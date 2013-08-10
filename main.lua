local Class     = require "hump.class"
local Vec       = require "hump.vector"
local Gamestate = require "hump.gamestate"
local Timer     = require "hump.timer"
local Camera    = require "hump.camera"

local lp = love.physics
local lg = love.graphics

local getRes = nil

if love.window then
	getRes = love.window.getMode
else
	getRes = love.graphics.getMode
end

maxw = 9000
rad = 64

local function newBody(x, y, shape, t)
	local body = lp.newBody(world, x, y, t or "dynamic")
	local fixture = lp.newFixture(body, shape)
	return body, fixture
end


local ballbuf = {}
function bdraw()
	local newbuf = {
		x = ball:getX(),
		y = ball:getY(),
		theta = ball:getAngle()
	}

	if #ballbuf > 10 then
		table.remove(ballbuf, 1)
	end
	table.insert(ballbuf, newbuf)

	for i, bdef in ipairs(ballbuf) do
		lg.setColor(255, 255, 255, 255/(#ballbuf-i))
		love.graphics.draw(bud,
									bdef.x, bdef.y, -- pos
									bdef.theta,          -- angle
									1, 1,      -- scale
									rad, rad)                 -- offset
		love.graphics.draw(budface,
									bdef.x, bdef.y,
									0,
									1, 1,
									rad, rad)
	end
end

function love.load()
	bud = love.graphics.newImage("bud.png")
	budface = love.graphics.newImage("bud-face.png")
	lp.setMeter(64)
	world = lp.newWorld(0, 0, true)
  	ball = newBody(100, 400, lp.newCircleShape(rad))
	local w, h = getRes()
	floor, floor_fix = newBody(0, h, lp.newEdgeShape(-maxw, 0, maxw, 0), "static")
	floor_fix:setRestitution(.4)
	cam = Camera()

	if love.window then
		love.window.setMode(800, 600, {fsaa = 0})
		lg.setDefaultFilter('nearest', 'nearest')
	else
		lg.setMode(960, 640, false, true, 6)
	end
	buf = lg.newCanvas()
	oldbuf = lg.newCanvas()
end

local function beginbuf()
	lg.setCanvas(buf)
	lg.clear()
end

local function endbuf()
	lg.setColor(235, 235, 255, 50)
	lg.draw(oldbuf)

	lg.setCanvas()
	lg.setColor(255, 255, 255, 255)
	lg.draw(buf)
	oldbuf, buf = buf, oldbuf
end


local function bg(back, fore)
	local sq = 256

	lg.push()
	local w, h = getRes()
	local cx, cy = cam:pos()
	local x, y = nil, -2
	local _ = 0
	lg.translate(w/2, h/2)
	lg.rotate(ang)

	local function to(x, y)
		return x * sq -(cx % (sq * 2)), y * sq + (cy % (sq * 2))
	end

	local row = false
	while Vec(to(_,y)).y < h * 2 do
		x = 0
		while Vec(to(x,_)).x < w * 2 do
			if (x + y) % 2 == 0 then
				lg.setColor(unpack(back))
			else
				lg.setColor(unpack(fore))
			end
			local ix, iy = to(x, y)
			lg.rectangle('fill', ix - w, iy - h, sq, sq)
			x = x + 1
		end
		y = y + 1
		row = not row
	end

	lg.pop()
end

function love.draw()
	local black = {50, 50, 50}
	local white = {255, 255, 255}
	local red   = {0, 0, 255}
	lg.setBackgroundColor(0, 255, 255)
	--beginbuf()
	bg(black, white)


	lg.setStencil(function()
		lg.setColor(255, 255, 255)
		local w, h = getRes()
		cam:attach()
		lg.polygon('fill', -maxw, h, maxw, h, maxw, h+1000, -maxw, h+1000)
		cam:detach()
	end)
	bg(black, red)
	lg.setStencil()

	cam:attach()
	bdraw()
	cam:detach()
	--endbuf()
end

local function mousetilt(dt)
	local x = love.mouse.getPosition()
	local w = getRes()
	local hw = w * .5
	return (x - hw) / hw
end

local function per(v, f)
	return Vec(f(v.x), f(v.y))
end

function love.update(dt)
	ang = mousetilt(dt) * .5
	local vel = Vec(ball:getLinearVelocity())
	local maxsp = 100000
	vel = per(vel, function(x) return math.tanh(x / maxsp) * maxsp end)
	ball:setLinearVelocity(vel:unpack())
	world:setGravity(Vec(0, 10*64):rotated(-ang):unpack())
	world:update(dt)

	cam:move(0, 100)
	local dcam = Vec(ball:getWorldCenter()) - Vec(cam:pos())
	cam:move((dcam * .5):unpack())
	cam:move(0, -100)
	cam:rotateTo(ang)
end


function love.mousepressed()
	ball:applyLinearImpulse(0, -30*64)
end

