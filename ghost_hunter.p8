pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

sprites={}
function _init()
	_update=start_update
	_draw=start_draw
end

function start_update()
	if (btnp(4)) then
		tt=0
		sprites={}

		player=player_init()
		add(sprites,player)

		ghost=ghost_init()
		add(sprites,ghost)

		_update=game_update
		_draw=game_draw
	end
end

function start_draw()
	cls()
	print("press z to start", 64, 64)
end

function game_update()
	tt+=1
	if tt<0 then
		tt=0
	end
	update_sprites()
	sort_sprites()
	if (btnp(4)) then
		_update=start_update
		_draw=start_draw
	end
end

function game_draw()
	cls(13)
	palt(0,false)
	palt(13,true)
	draw_sprites()
end

function update_sprites()
	for i=1,#sprites do
		sprites[i]:update()
	end
end

function draw_sprites()
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
-->8
--player

player={}
friction=0.8
max_speed=1.5

function player_init()
	self={
		x=64,
		y=64,
		dx=0,
		dy=0,
		turned=false,
		frame_head=1,
		frame_body_idle=17,
		frame_body_walk={18, 17, 19},
		frame_body_walk_index=1,
	}
	
	function self:update()
		self:get_input()
		self:move()
		self:animate()
	end
	
	function self:draw()
		self:draw_head()
		self:draw_body()
	end

	function self:get_input()
		self.dx*=friction
		self.dy*=friction
		if abs(self.dx)<0.1 then
			self.dx=0
		end
		if abs(self.dy)<0.1 then
			self.dy=0
		end
		if btn(⬅️) then
			self.dx-=1
			self.turned=true
		end
		if btn(➡️) then
			self.dx+=1
			self.turned=false
		end
		if btn(⬆️) then
			self.dy-=1
		end
		if btn(⬇️) then
			self.dy+=1
		end
		if abs(self.dx)>max_speed then
			local sign=abs(self.dx)/self.dx
			self.dx=max_speed*sign
		end
		if abs(self.dy)>max_speed then
			local sign=abs(self.dy)/self.dy
			self.dy=max_speed*sign
		end
	end

	function self:move()
		self.x+=self.dx
		self.y+=self.dy
	end

	function self:animate()
		self:animate_body()
	end

	function self:animate_body()
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
		spr(self.frame_head,self.x,self.y,1,1,self.turned)
	end

	function self:get_frame_body()
		if self.dx==0 and self.dy==0 then
			return self.frame_body_idle
		else
			return self.frame_body_walk[self.frame_body_walk_index]
		end
	end

	function self:draw_body()
		spr(self:get_frame_body(),self.x,self.y+8,1,1,self.turned)
	end
	
	return self
end
-->8
--ghost

ghost={}
proximity=10

function ghost_init()
	self={
		x=64,
		y=64,
		dx=0,
		dy=0,
		hover=0,
		turned=false,
		frame_head=5,
		frame_body={21,22,21,23},
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
		if abs(player.x-self.x)<proximity and abs(player.y-self.y)<proximity then
		else
			self:move_to_player()
		end
	end

	function self:move_to_player()
		local angle=atan2(player.x-self.x,player.y-self.y)
		self.dx=cos(angle)
		self.dy=sin(angle)
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
		self.hover=cos(tt/100)*2-10
	end

	function self:draw_head()
		local y=self.y+self.hover
		spr(5,self.x,y,1,1,self.turned)
	end

	function self:get_frame_body()
		return self.frame_body[self.frame_body_index]
	end


	function self:draw_body()
		local y=self.y+self.hover+8
		spr(self:get_frame_body(),self.x,y,1,1,self.turned)
	end

	return self
end
__gfx__
00000000dd888888dd888888dd88888800000000dddddddddddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000
00000000d888aaaad888aaaad888aaaa00000000dddddddddddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000
0070070088affffd88affffd88affffd00000000ddd777ddddd777ddddd777dd0000000000000000000000000000000000000000000000000000000000000000
0007700088ff0f0d88ff0f0d88ff0f0d00000000dd77777ddd77777ddd77777d0000000000000000000000000000000000000000000000000000000000000000
00077000aaf070fdaaf070fdaaf070fd00000000d777777dd777777dd777777d0000000000000000000000000000000000000000000000000000000000000000
00700700aaff0fffaaff0fffaaff0fff00000000d770707dd770707dd770707d0000000000000000000000000000000000000000000000000000000000000000
00000000aaeffffdaaeffffdaaeffffd00000000d770707dd770707dd770707d0000000000000000000000000000000000000000000000000000000000000000
00000000aafeefddaafeefddaafeefdd00000000d777777dd777777dd777777d0000000000000000000000000000000000000000000000000000000000000000
0000000078ffff8778ffff8778ffff8700000000d777777dd777777dd777777d0000000000000000000000000000000000000000000000000000000000000000
0000000078777787787777877877778700000000d777777dd777777dd777777d0000000000000000000000000000000000000000000000000000000000000000
00000000f888888ff888888ff888888f00000000d777d7ddd77d7d7dd77d7d7d0000000000000000000000000000000000000000000000000000000000000000
00000000d888888dd888888dd888888d00000000d7d7ddddd77ddddddd7ddddd0000000000000000000000000000000000000000000000000000000000000000
00000000d888d88ddffdd88dd888dffd00000000ddddddddd7dddddddddddddd0000000000000000000000000000000000000000000000000000000000000000
00000000dffddffddaaadffddffddaaa00000000dddddddddddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000
00000000daaadaaadddddaaadaaadddd00000000dddddddddddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000
00000000dddddddddddddddddddddddd00000000dddddddddddddddddddddddd0000000000000000000000000000000000000000000000000000000000000000
