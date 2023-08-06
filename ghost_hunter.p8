pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--main

sprites={}
cell_size=8
row_size=16
big_size=8
big_size=32
big_size=16
function _init()
	_update=start_update
	_draw=start_draw
end

function start_update()
	if (btnp(🅾️)) then
		tt=0
		sprites={}

		player=player_init()
		add(sprites,player)

		add(sprites,ghost_init())

		world=world_init()

		_update=game_update
		_draw=game_draw
	end
end

function start_draw()
	cls()
	local message="press 🅾️ to start"
	print(message,64-(#message*8)/4-2,64,7)
end

function game_update()
	tt+=1
	if tt<0 then
		tt=0
	end
	update_sprites()
	sort_sprites()
end

function game_draw()
	palt(0,false)
	palt(13,true)
	world:draw()
	draw_sprites()
end

function update_sprites()
	for i=1,#sprites do
		sprites[i]:update()
	end
end

function draw_sprites()
	clip(0,64,128,64)
	for i=1,#sprites do
		sprites[i]:draw_shadow()
	end
	clip()
	for i=1,#sprites do
		sprites[i]:draw()
	end
end

function sort_sprites()
	for i=1,#sprites do
		for j=1,#sprites do
			if sprites[i].y<sprites[j].y then
				sprites[i],sprites[j]=sprites[j],sprites[i]
			end
		end
	end
end

function zspr(frame,x,y,flip_x,flip_y)
	local sx=flr(frame%row_size)*cell_size
	local sy=flr(frame/row_size)*cell_size

	sspr(sx,sy,cell_size,cell_size,x,y,big_size,big_size,flip_x,flip_y)
end

function draw_shadow_line(a,b,n,x,y)
	for d=1,3 do
		for j=1,a do
			for k=1,a do
				pset(x+n*b+d*a+j-a,y-d*a+k,0)
			end
		end
	end
end
-->8
--player

player={}
player_speed=1*big_size/cell_size
friction=0.8
gravity=0.2*big_size/cell_size
max_speed_x=1.5*big_size/cell_size
max_speed_y=.75*big_size/cell_size

function player_init()
	local self={
		x=64,
		y=64,
		dx=0,
		dy=0,
		turned=false,
		frame_head=1,
		frame_body_idle=17,
		frame_body_walk={18, 17, 19},
		frame_body_walk_index=1,
		boost=-1.7*big_size/cell_size,
		vy=0,
		ty=0,
		hold_jump=0,
		ready_jump=true,
		go_jump=false,
	}
	
	function self:update()
		self:get_input()
		self:collision()
		self:move()
		self:animate()
	end
	
	function self:draw()
		self:draw_body()
		self:draw_head()
	end

	function self:get_input()
		local speed=player_speed
		self.dx*=friction
		self.dy*=friction
		if abs(self.dx)<0.1 then
			self.dx=0
		end
		if abs(self.dy)<0.1 then
			self.dy=0
		end
		if btn(⬅️) then
			self.dx-=speed
			self.turned=true
		end
		if btn(➡️) then
			self.dx+=speed
			self.turned=false
		end
		if btn(⬆️) then
			self.dy-=speed
		end
		if btn(⬇️) then
			self.dy+=speed
		end

		if not self.go_jump then
			if self.ready_jump and btn(❎) then
				self.hold_jump+=1
			elseif self.hold_jump>0 then
				self.go_jump=true
			end
		end

		if self.hold_jump>0 and self.go_jump then
			local a=mid(.2,self.hold_jump/10,1)
			self.vy=a*self.boost
			self.ready_jump=false
			self.hold_jump=0
		end
		if self.ty<0 then
			self.vy+=gravity
		end
		local mx=max_speed_x
		local my=max_speed_y
		if self.hold_jump>0 and not self.go_jump then
			mx*=0.25
			my*=0.25
		end
		if abs(self.dx)>mx then
			local sign=abs(self.dx)/self.dx
			self.dx=mx*sign
		end
		if abs(self.dy)>my then
			local sign=abs(self.dy)/self.dy
			self.dy=my*sign
		end
	end

	function self:collision()
		self:collision_floor()
		self:collision_map()
		--self:collision_sprites()
	end

	function self:collision_floor()
		if self.vy>0 and self.ty>=0 and self.go_jump then
			self.ty=0
			self.vy=0
			self.ready_jump=true
			self.go_jump=false
		end
	end

	function self:collision_map()
		local x1=flr(self.x/cell_size)
		local y1=flr(self.y/cell_size)
		local x2=flr((self.x+big_size-1)/cell_size)
		local y2=flr((self.y+big_size-1)/cell_size)
		local x3=flr((self.x+big_size-1)/cell_size)
		local y3=flr(self.y/cell_size)
		local x4=flr(self.x/cell_size)
		local y4=flr((self.y+big_size-1)/cell_size)
	end

	function self:move()
		self.x+=self.dx
		self.y+=self.dy
		self.ty+=self.vy
	end

	function self:animate()
		self:animate_body()
	end

	function self:animate_body()
		if self.ty<0 then
			return
		end
		if self.dx==0 and self.dy==0 then
			self.frame_body_walk_index=1
		else
			if tt%4==0 then
				self.frame_body_walk_index+=1
			end
			if self.frame_body_walk_index>#self.frame_body_walk then
				self.frame_body_walk_index=1
			end
		end
	end

	function self:draw_head()
		local y=self.y+self.ty
		if self.hold_jump>0 then
			y+=1*big_size/cell_size
		end
		zspr(self.frame_head,self.x,y,self.turned)
	end

	function self:get_frame_body()
		if self.dx==0 and self.dy==0 then
			return self.frame_body_idle
		else
			return self.frame_body_walk[self.frame_body_walk_index]
		end
	end

	function self:draw_body()
		local y=self.y+self.ty
		zspr(self:get_frame_body(),self.x,y+big_size,self.turned)
	end

	function self:draw_shadow()
		if self.ty<0 then
			self:draw_shadow_line(-1)
			self:draw_shadow_line(0)
			self:draw_shadow_line(1)
			--self:draw_shadow_circle()
		end
	end
	function self:draw_shadow_circle()
		if self.ty<0 then
			local a=big_size/cell_size
			local b=max(3,self.ty*a/self.boost)
			local x=self.x+big_size/2
			local y=self.y+big_size*2-a
			--circfill(x,y,abs(self.ty)*a,5)
			ovalfill(x-b,y-a,x+b,y+a,5)
		end
	end

	function self:draw_shadow_line(n)
		local a=big_size/cell_size
		local b=mid(big_size/4,self.ty*a/self.boost,big_size/2)
		local x=self.x+big_size/4
		local y=self.y+2*(big_size)

		draw_shadow_line(a,b,n,x,y)
	end

	
	return self
end
-->8
--ghost

ghost_speed=big_size/cell_size
near=10*big_size/cell_size
close=20*big_size/cell_size

function ghost_init()
	local self={
		x=128-256*flr(rnd(2)),
		y=flr(rnd(32)),
		dx=0,
		dy=0,
		hover_p=0,
		hover_y=0,
		turned=false,
		frame_head=33,
		frame_body={49,50,49,51},
		frame_body_index=1,
	}

	function self:update()
		self:move()
		self:animate()
	end

	function self:draw()
		self:draw_head()
		self:draw_body()
	end

	function self:move()
		if abs(player.x-self.x)<near and abs(player.y-self.y)<near then
		else
			self:move_to_player()
		end
	end

	function self:move_to_player()
		local a=ghost_speed
		if abs(player.x-self.x)<close and abs(player.y-self.y)<close then
			a=ghost_speed/2
		end
		local angle=atan2(player.x-self.x,player.y-self.y)
		self.dx=cos(angle)*a
		self.dy=sin(angle)*a
		self.x+=self.dx
		self.y+=self.dy
		if self.dx<0 then
			self.turned=true
		else
			self.turned=false
		end
	end

	function self:animate()
		self:animate_body()
	end

	function self:animate_body()
		if tt%4==0 then
			self.frame_body_index+=1
		end
		if self.frame_body_index>#self.frame_body then
			self.frame_body_index=1
		end
		local a=big_size/cell_size
		self.hover_p=cos(tt/100)
		self.hover_y=a*self.hover_p*2-a*10
	end

	function self:draw_head()
		local x=self.x
		local y=self.y+self.hover_y
		zspr(self.frame_head,x,y,self.turned)
	end

	function self:get_frame_body()
		return self.frame_body[self.frame_body_index]
	end


	function self:draw_body()
		local x=self.x
		local y=self.y+self.hover_y+big_size
		zspr(self:get_frame_body(),x,y,self.turned)
	end

	function self:draw_shadow()
		self:draw_shadow_line(-1)
		self:draw_shadow_line(0)
		self:draw_shadow_line(1)
	end

	function self:draw_shadow_line(n)
		local a=big_size/cell_size
		local b=big_size/4
		local x=self.x+big_size/4
		local y=self.y+2*(big_size)
		draw_shadow_line(a,b,n,x,y)
	end

	return self
end
-->8
--map

world={}

function world_init()
	local self={}
	
	function self:update()
	end
	
	function self:draw()
		cls(1)
		rectfill(0,64,128,128,3)
	end
	
	return self
end
__gfx__
00000000dd888888dd888888dd888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d888aaaad888aaaad888aaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070088affffd88affffd88affffd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700088ff0f0d88ff0f0d88ff0f0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000aaf070fdaaf070fdaaf070fd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700aaff0fffaaff0fffaaff0fff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaeffffdaaeffffdaaeffffd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aafeefddaafeefddaafeefdd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000078ffff8778ffff8778ffff87000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000787777877877778778777787000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000f888888ff888888ff888888f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d888888dd888888dd888888d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d888d88ddffdd88dd888dffd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000dffddffddaaadffddffddaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000daaadaaadddddaaadaaadddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000dddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000dddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000dddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ddd777ddddd777ddddd777dd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000dd77777ddd77777ddd77777d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d777777dd777777dd777777d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d770707dd770707dd770707d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d770707dd770707dd770707d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d777777dd777777dd777777d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d777777dd777777dd777777d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d777777dd777777dd777777d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d777d7ddd77d7d7dd77d7d7d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d7d7ddddd77ddddddd7ddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ddddddddd7dddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000dddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000dddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000dddddddddddddddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
