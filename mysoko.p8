pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--init & stargame

--sprite flags
--0:wall
--1:goal
--2:

function _init()
	t=0
	fadeperc=1
	cam_y=0
	cam_x=0
	debug={}
	level=0
	p_anims={112,116}
	p_ani=loadani(p_anims[1])
	
	levelx={17,34,51,68,85,102,0,17,34,51,68,85,102}
	levely={0,0,0,0,0,0,16,16,16,16,16,16,16}
	
	boxtles={6,7,8,9}
	goaltles={22,23,24,25}

	dpal={0,1,1,2,1,13,6,4,4,9,3,13,1,13,14}
	--FUTURE: CHANGE ARRAYS TO HAVE
	--{START_ANI,#IN_ANI,SPEED}
	--SPEED CAN CHANGE DIV TO SLOW 
	--OR SPEED ANIMATION

	dirx={-1,1,0,0,1,1,-1,-1}
	diry={0,0,-1,1,-1,1,1,-1}
	
	box={}
	goal={}
	lock={0,0,0}
	slock=4--SIZE of LOCK+GOAL
	
	slbx=nil --SLIDE BOX
	
	init_menu()
	
end

function init_game()
	
	buttbuff=-1
	p_x,p_y=22,10
	p_ox,p_oy=0,0--PLAYER OFFSET
	--OFFSET ALLOWS PLAYER TO SLIDE
 --INTO A GIVEN SPOT WITHOUT
 --LOSING POSITION	
	
	p_flp=false
	p_mov=nil
	p_t=0--ANIMATION TIMER (0 TO 1)
	
	wind={}--WINDOW ARRAY
	talkwind=nil
	
	
	
	_upd=upd_level
	_drw=draw_game
	
	--music(32,1000)
end
-->8
--update

function _update()
	t+=1--where we are in the anim
	_upd()
end 

function upd_game()
	if talkwind then
 	if	getinput()==5 then
			talkwind.dur=0--close box
			talkwind=nil
		end
	else
		btn_buffer()
		do_btn_buffer(buttbuff)
		buttbuff=-1
	end
	if checksolved() then
		--end level
		_upd=upd_level
		fadeout(0.5)
		--sfx(54)
	end
end


-->8
--draw
--______________________________new animation system

--WORKS FOR 2x2 AND SINGLE FRAME ANIMS
function create_ani_list(_sa,_ea,_delay,grid)
	local _ani={}
	--add delay
	if _delay>0 then
		for x=0,_delay do
			add(_ani,_sa)
		end
	end
	--add normal frames

	local length=_ea
	local skip=0
	if grid then
		length=(_ea-_sa)/2+_sa
	end
	for x=_sa,length do
		add(_ani,x+skip)
		if grid then
			skip+=1
		end
	end
	return _ani

end

function add_ani(_sa,_ea,_delay,_spd,_x,_y,_flp)
	local _ani = create_ani_list(_sa,_ea,_delay,false)
	local a={
		ani=_ani,
		spd=_spd,--SPD OF ANI LOWER BETTER?
		x=_x,
		y=_y,
		flp=_flp

	}
	add(anims,a)
end



function draw_bas_ani()
	for a in all(anims) do
		fm=getframe(a.ani,a.spd)
		drawspr(fm,a.x,a.y,a.flp)
	end
end

--ONLY ADD 2x2 ANIMATED GRIDS
function add_grid(_sa,_ea,_delay,_spd,_x,_y,_w,_h)
	
	local _ani=create_ani_list(_sa,_ea,_delay,true)
	
	local a={
		ani=_ani,
		spd=_spd,
		x=_x,
		y=_y,
		w=_w,
		h=_h

	}
	add(grids,a)
end

function drawgrids()
	for g in all(grids) do
		--SINCE LOOP STARTS AT 0
		gw,gh=g.w-1, g.h-1	
		for x=0,gw do
			for y=0,gh do
				sp=getframe(g.ani,g.spd)
				drawspr(y*16+sp+x,g.x+x*8,g.y+y*8,false)
			end
		end
	end
end

function sdrawgrid(stspr,_x,_y,_w,_h)
	_w,_h=_w-1,_h-1--since start 0	
	for x=0,_w do
		for y=0,_h do		
			drawspr(y*16+stspr+x,_x+x*8,_y+y*8,false)
		end
	end
end

function getframe(ani,spd)
	return ani[flr(t/spd)%#ani+1]
end

function drawspr(_spr,_x,_y,_flp)
	spr(_spr,_x,_y,1,1,_flp)	
end

function drawgamestuff()

	--draw desk
	---------------
	sdrawgrid(10,cam_x+2*8,cam_y+1*8,3,2)
	---------------
	--monitor
	add_ani(96,98,0,6,cam_x+3*8,cam_y+1*8,false)
	--chord
	add_ani(99,102,4,4,cam_x+4*8,cam_y+1*8,false)
	--coin
	add_grid(37,43,4,4,16*3+cam_x+5*8,cam_y+1*8,2,2)
	--lower bar
	for x=0,15 do
		drawspr(32,cam_x+x*8,cam_y+24,false)
	end
	draw_bas_ani()
	drawgrids()
	drawlock()
end


function drawbox(b)
 	drawspr(b.tle,b.x*8+b.ox,b.y*8+b.oy,false)
end

function drawlock()
	for i=1,slock-1 do
		local _spr
		if lock[i]==1 then
			_spr=70
		else
			_spr=64
		end
		sdrawgrid(_spr,16*(i-1)+cam_x+5*8,cam_y+1*8,2,2)
	end
		
end

--______________________________

function _draw()
	grids={}
	anims={}
	_drw()
	drawind()
	checkfade()
	--draw debug
	local offst=0
	for txt in all(debug) do
		print(txt,cam_x+58,cam_y+offst)
		offst+=8
	end
end

function draw_game()
	cls()
	--CHANGE TRANSPARENCY COLR
	palt(0,false)
	palt(14,true)
	map()
	
	for b in all(box) do
		drawbox(b)
	end
	--draw player
	drawspr(getframe(p_ani,6),p_x*8+p_ox,p_y*8+p_oy,p_flp)
	--draw everything else in the game
	drawgamestuff()
 	--RETURN TRANSPARENCY COLR
	palt(0,true)
	palt(14,false)
end


--tool

function oprint8(_t,_x,_y,_c,_c2)
	for i=1,8 do
		print(_t,_x+dirx[8],_y+diry[i],_c2)		
	end
	print(_t,_x,_y,_c)
end

function rectfill2(_x,_y,_w,_h,_c)
	--★
	rectfill(_x,_y,_x+max(_w-1,0),_y+max(_h-1,0),_c)
end

function loadani(stani)
	local _ani={}
	for i=0,3 do
		_ani[i]=stani+i
	end
	return _ani
end


function wait(_wait)
 repeat
		_wait-=1
		flip()
	until _wait<0
end
-->8
--gameplay

function moveplayer(dx,dy)
	local newpx=p_x+dx
	local newpy=p_y+dy	
	--removed p_flip stuff

	--planned tile to move to
	local tle=mget(newpx,newpy)
	--wall flag
	local bx = checkbox(newpx,newpy)
	if fget(tle,0) or bx then
		p_sox=dx*8
		p_soy=dy*8
		p_ox,p_oy=0,0
		
		_upd=upd_player_loop--set player loop
		p_mov=mov_bump--set to bump
		--box flag
		if bx then
			slbx=bx
			bx.dx=dx
			bx.dy=dy
		else
			sfx(56)
		end
	else
		--no wall or box
		sfx(63)
		p_x+=dx
		p_y+=dy

		--SET OFFSET USED IN player loop
		p_sox=-dx*8
		p_soy=-dy*8
		 
		p_ox,p_oy=p_sox,p_soy
		_upd=upd_player_loop
		p_mov=mov_walk--set to walk
	end
	p_t=0
end

--this pauses player movement
--to animate
function upd_player_loop()
	btn_buffer()
	p_ani=loadani(p_anims[2])
	p_t=min(p_t+0.3,1)
	p_mov() --moves the player offset by
	if p_t==1 then
		--call slide box
		p_ani=loadani(p_anims[1])
		_upd=upd_game
		if slbx then
			movebox()
		end
	end
end

function mov_walk()
	p_ox=p_sox*(1-p_t)
	p_oy=p_soy*(1-p_t)	
end

function mov_bump()
	local tme=p_t
	--go back the second half of the animation
	if p_t>0.5 then
		tme=1-p_t
	end
		p_ox=p_sox*tme
		p_oy=p_soy*tme
end

function btn_buffer()
	if buttbuff==-1 then
		buttbuff=getinput()
	end
end

function getinput()
	for i=0,5 do
		if btnp(i) then
			return i
		end
	end 
	return -1
end

function do_btn_buffer(_btn)
 if 0<=_btn and _btn<4 then
	 moveplayer(dirx[_btn+1],diry[_btn+1])
 end
 --menu button
end

function checksolved()
	local solved = true	
	for g in all(goal) do
		if checkbox(g.x,g.y) then
		 mset(g.x,g.y,13)
		 if not g.flg then
		 	g.flg = true
		 	sfx(55)
   end
		else
			mset(g.x,g.y,g.gf)
			g.flg=false
			solved = false
		end
	end
	return solved
end


function upd_level()
	--change camera 17*8=136
	modlvl=level%slock
	level+=1
	debug[1]="level "..level
	

	local lx=levelx[level]
	local ly=levely[level]
	--debug[2]=#levelx ..":"..#levely
	
	cam_x=8*lx
	cam_y=8*ly
	camera(cam_x,cam_y)--pixel location
	--player stuff

	p_x=lx+1
	p_y=ly+5
	--lock stuff



	if modlvl==0 then
		lock={}
	else
		lock[modlvl]=1
	end

	--INITIALIZE BOX AND GOAL
	box={}
	goal={}
	--LOAD UP THE BOXES AND GOALS
	for x=lx,lx+15 do
		for y=ly,ly+10 do
			tle=mget(x,y)
			--ALL THE BOX TYPES
			for t in all(boxtles) do
				if t==tle then
					addbox(tle,x,y)
					mset(x,y,1)--SET GROUND TYLE
				end
			end
			--ALL THE GOAL TYPES
			for t in all(goaltles) do
				if t==tle then
					addgoal(tle,x,y)
				end
			end
		end
	end
		--set the state for the game
	_upd=upd_game 
	_drw=draw_game
	
end
-->8
--ui and juice

function addwind(_x,_y,_w,_h,_txt)
	local w={x=_x,y=_y,w=_w,h=_h,txt=_txt}
	add(wind,w)
	return w
end

function drawind()
	for w in all(wind) do
		local wx,wy,ww,wh=w.x,w.y,w.w,w.h
		rectfill2(wx,wy,ww,wh,0)		
		rect(wx+1,wy+1,wx+ww-2,wy+wh-2,6)
		--text offset
		wx+=4
		wy+=4
		clip(wx,wy,ww-8,wh-8)
 	for i=1,#w.txt do
			local txt=w.txt[i]
			print(txt,wx,wy,11)
			wy+=6--next line of text
		end
		
		clip()--reset clip
		
		--closing window
		if w.dur!=nil then
			w.dur-=1
			if w.dur<=0 then
				local dif=wh/4--close amnt
				w.y+=dif/2
				w.h-=dif
				if wh<1 then
					del(wind,w)
				end
			end
		else
			if w.butt then
				oprint8("❎",wx+ww-15,wy-1+sin(time()),6,0)
			end
		end
	end
end

function showmsg(txt,dur)
 local wid=(#txt+2)*4+7
 local w=addwind(63-wid/2,50,wid,13,{" "..txt})
 w.dur=dur
end

function showmsg(txt)
 talkwind=addwind(16,50,94,#txt*6+7,txt)
 talkwind.butt=true
end

function dofade()
 local p,kmax,col,k=flr(mid(0,fadeperc,1)*100)
 for j=1,15 do
  col = j
  kmax=flr((p+j*1.46)/22)
  for k=1,kmax do
   col=dpal[col]
  end
  pal(j,col,1)
 end
end


function fadeout(spd,_wait)
 if (spd==nil) spd=0.04
 if (_wait==nil) _wait=0
 repeat
  fadeperc=min(fadeperc+spd,1)
  dofade()
  flip()
 until fadeperc==1
 wait(_wait)
end

function checkfade()
	if fadeperc>0 then
		fadeperc=max(fadeperc-0.04,0)
		dofade()
	end
end


--menu
--(will move to ui when done)

function init_menu()
	_upd=upd_menu
	_drw=drw_menu
	--music(1,0)
end

function upd_menu()
	if btnp(❎) then
		fadeout()
		init_hub()
		--sfx(59)
	end
end

function drw_menu()
	cls()
	oprint8("press ❎ to start",30,50+sin(time()),7,13)
end

-->8
--box and goal

--goal
function addgoal(tle,gx,gy) 
	local g={
		x=gx,
		y=gy,
		gf=tle,--tile normally
		flg=false
	}
	add(goal,g)
end

--box movement
function addbox(btle,bx,by) 
	local b={
		x=bx,
		y=by,
		ox=0,
		oy=0,
		tle=btle
	}
	add(box,b)
end

function checkbox(x,y)
	for b in all(box) do
 	if b.x==x and b.y==y then
 		return b
 	end
 end
 return false--NO BOX FOUND
end

function movebox()
		pushto=mget(slbx.x+slbx.dx,slbx.y+slbx.dy)
		--IF WALL
		if fget(pushto,0) or checkbox(slbx.x+slbx.dx,slbx.y+slbx.dy) then
			sfx(56)
			slbx=nil
		else
			--PUSH BLOCK
			p_t=0
			slbx.x+=slbx.dx--SET NEW DESTINATION
			slbx.y+=slbx.dy
			slbx.sox=-slbx.dx*8--STARTING OFFSET
			slbx.soy=-slbx.dy*8
			slbx.ox,slbx.oy=slbx.sox,slbx.soy
			
			_upd=upd_box_loop
			sfx(58)
		end
end

--LOOP UNTIL BOX FINISHES MOVING
function upd_box_loop()
	btn_buffer()
	p_t=min(p_t+.4,1)
	boxslide(slbx,p_t)
	if p_t ==1 then
		_upd=upd_game
		slbx=nil
	end
end

function boxslide(b,p_t)
	b.ox=b.sox*(1-p_t)
	b.oy=b.soy*(1-p_t)	
end
-->8
--hub
function init_hub()
	_upd=upd_hub
	_drw=drw_hub
	hubsel=0
end


function upd_hub()
	hubinput()
end

function hubinput()
	local _btn=getinput()
	if _btn==⬆️ then	--up
		hubsel=(hubsel-1)%3
		sfx(52)
	elseif _btn==⬇️ then--down
		hubsel=(hubsel+1)%3
		sfx(52)
	elseif _btn==5 then
		sfx(51)
		selworld()
	end
end

function selworld()
	--worlds: 1-5
	level=0--start level 1 less,
	init_game()
	fadeout()
end


function drw_hub()
	cls()
	map()
	--draw coin
	add_grid(37,43,4,4,16*3+cam_x+5*8,cam_y+1*8,2,2)
	--cursor
	drawcursor()
end

function drawcursor()
	--sa,ea,delay,spd
	add_ani(2,3,3,10, 8,8*(10+2*(hubsel)), false)
	draw_bas_ani()
	drawgrids()
end

__gfx__
000000000000000000000000000000000000000001000010eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee3bbbbbb30000000000000000
000000000000000000330000000000006666666001000010e55555eeee6ee6eee656565eeeddddeeeeeeeeeeeeeeeeeeeeeeeeeeb3bbbb3b0000000000000000
007007000000000000003300000000006333336001000010e522225ee555555ee777775eed1111deeeeeeeeeeeeeeeeeeeeeeeeebb3bb3bb0000000000000000
000770000000000000000030000000006333336001000010e522225ee522225ee7ddd75eed1dd1de4eeeeeeeeeeeeeeeeeeeeeeebbb33bbb0000000000000000
000770000000000000000030000000006666b86001055010e555555ee522225ee777775eed1dd1de4eeeeeeeeeeeeeeeeeeeeeeebbb33bbb0000000000000000
007007000005000000003300000000006655566005666650e599995ee555555ee7ddd75eed1111de4eeeeeeeeeeeeeeeeeeeeeeebb3bb3bb0000000000000000
00000000000000000033000000000000666666600566b850e5aaaa5eee6ee6eee77777eeeeddddee54eeeeeeeeeeeeeeeeeeeeeeb3bbbb3b0000000000000000
000000000000000000000000000000005555555005555550eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee54eeeeeeeeeeeeeeeeeeeeee3bbbbbb30000000000000000
111111505505555500000000000000000000000006666660e464464ee444444e6555555600000ddd54eeeeee666ddddddddddddd000000000000000000000000
11111150dd0ddddd00000000000000000000000006bbbb6046444464444444446666666600000d8de54eeeeedddddd555555555d000000000000000000000000
111111500000000000666666666666666666660006bbbb60464444644644446466c6cc66dddddddde544444e55555deeeeeeee5d000000000000000000000000
111111505555055500666666666666666666660006bbbb6044644644445555446c6666c6d000000de545554eeeee5deeeeeeee5d000000000000000000000000
11111150dddd0ddd0066666666666666666666000dddddd044644644445555446c6666c6dddddddde45eeee4eeee5deeeeeeee5d000000000000000000000000
111111500000000000666555555555555556660006666660446446444644446466cc6c6600000000e45eeee4eeee5deeeeeeee5d000000000000000000000000
5555555055055555006665000000000000566600065555604555555444444444666666660000000045eeeeee4eee5deeeeeeee5d000000000000000000000000
00000000dd0ddddd00666500000000000056660006666660e555555ee444444ee666666e0000000045eeeeee4eee5deeeeeeee5d000000000000000000000000
55555555555555500066650000000000005666000000066666000000000000060000000000000006000000000000000600000000000000000000000000000000
11111111666666600066650000000000005666000006655555660000000000656000000000000066600000000000006560000000000000000000000000000000
111111116655566000666500000000000056660000655ddddd5560000000065d6600000000000066600000000000066d56000000000000000000000000000000
1111111105050500006665000000000000566600065dddd6dddd5600000065ddd66000000000006660000000000066ddd5600000000000000000000000000000
1111111155666550006665000000000000566600065ddd6d6ddd5600000065ddd66000000000006660000000000066ddd5600000000000000000000000000000
111111116666666000666500033333300056660065ddd6ddd6ddd56000065dd6dd660000000000660000000000066dd6dd560000000000000000000000000000
111111115555555000666500000000000056660065ddd66dd6ddd56000065dd6dd660000000000660000000000066dd6dd560000000000000000000000000000
555555550000000000666500000000000056660065ddd666d6ddd56000065dd6dd660000000000660000000000066dd6dd560000000000000000000000000000
000000005555555000666500000000000056660065ddd666d6ddd56000065dd6dd660000000000660000000000066dd6dd560000000000000000000000000000
030000306655566000666555555555555556660065ddd6ddd6ddd56000065dd6dd660000000000060000000000066dd6dd560000000000000000000000000000
0033330000050000006666666666666666666600065ddd6d6ddd5600000065ddd66000000000000660000000000066ddd5600000000000000000000000000000
0366663000000000006666666666666666666600065dddd6dddd5600000065ddd66000000000000660000000000066ddd5600000000000000000000000000000
03bbbb300500050000666666666666666666660000655ddddd5560000000065d6600000000000066600000000000066d56000000000000000000000000000000
3b3333b3556665500066666666666666666666000006655555660000000000666000000000000066600000000000006660000000000000000000000000000000
33000033555555500066666666666666666666000000066666000000000000060000000000000006000000000000000600000000000000000000000000000000
03300330000000000066666666666666666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e55555555555555ee56666666666665ee56666666666665ee55555555555555e0000000000000000000000000000000000000000000000000000000000000000
e59999999999995ee56666666666665ee56666666666665ee53333333333335e0000000000000000000000000000000000000000000000000000000000000000
e59999999999995ee56666666666665ee56666666666665ee53333333333335e0000000000000000000000000000000000000000000000000000000000000000
e59999999999995ee56666666666665ee56666666666665ee55335555553355e0000000000000000000000000000000000000000000000000000000000000000
e59999999999995ee56666666666665ee55665555556655eee5335eeee5335ee0000000000000000000000000000000000000000000000000000000000000000
e59999999999995ee55665555556655eee5665eeee5665eeee5555eeee5555ee0000000000000000000000000000000000000000000000000000000000000000
e55995555559955eee5665eeee5665eeee5555eeee5555eeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000
ee599559955995eeee555555555555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000
e55555599555555eeeeeee5665eeeeeeeeeeee5555eeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000
e59999999999995ee55555566555555eeeeeee5665eeeeeeeeeeee5555eeeeee0000000000000000000000000000000000000000000000000000000000000000
e59999999999995ee56666666666665ee55555566555555eeeeeee5335eeeeee0000000000000000000000000000000000000000000000000000000000000000
e59999999999995ee56666666666665ee56666666666665ee55555533555555e0000000000000000000000000000000000000000000000000000000000000000
e59999999999995ee56666666666665ee56666666666665ee53333333333335e0000000000000000000000000000000000000000000000000000000000000000
e59999999999995ee56666666666665ee56666666666665ee53333333333335e0000000000000000000000000000000000000000000000000000000000000000
e55555555555555ee55555555555555ee55555555555555ee55555555555555e0000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000
eeee555eeeee555eeeee555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000
eeeeb555eeeeb555eeee3555eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000
eee3b565eeeb3565eeebb5655eeeeeee5eeeeeee5eeeeeee5eeeeeee000000000000000000000000000000000000000000000000000000000000000000000000
eeeb3566eeebb566eee3b5665eeeeeee5eeeeeee5eeeeeee5eeeeeee000000000000000000000000000000000000000000000000000000000000000000000000
eeebb566eee3b566eeeb356655eeeeee55eeeeee55eeeeee55eeeeee000000000000000000000000000000000000000000000000000000000000000000000000
eee3b566eeeb3566eeebb56665ee55ee65ee55ee65eeccee65ee55ee000000000000000000000000000000000000000000000000000000000000000000000000
eeee3566eeeeb566eeeeb56665e5ee5e65ecee5e65e5ee5e65e5eece000000000000000000000000000000000000000000000000000000000000000000000000
eeee5555eeee5555eeee5555555eeee555ceeee5555eeee5555eeeec000000000000000000000000000000000000000000000000000000000000000000000000
ee1eeeeeee1eeeeeee1eeeeeee7eeeeeeee1eeeeeee1eeeeeee1eeeeeee7eeee0000000000000000000000000000000000000000000000000000000000000000
e761eeeee161eeeee167eeeee767eeeeee76eeeeee16eeeeee16eeeeee76eeee0000000000000000000000000000000000000000000000000000000000000000
e7661eeee1661eeee1667eeee7661eeeee76eeeeee16eeeeee16eeeeee76eeee0000000000000000000000000000000000000000000000000000000000000000
e76661eee16661eee16667eee76661eeee761eeeee161eeeee167eeeee761eee0000000000000000000000000000000000000000000000000000000000000000
e766661ee166661ee166667ee166661eee7661eeee1661eeee1667eeee1661ee0000000000000000000000000000000000000000000000000000000000000000
e76611eee76677eee16617eee16611eeee761eeeee767eeeee167eeeee161eee0000000000000000000000000000000000000000000000000000000000000000
ee1161eeee7767eeee1167eeee1161eeeee11eeeeee77eeeeee17eeeeee11eee0000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1213131313131313131313131313131400101010101010101010101010101010100010101010101010101010101010101010001010101010101010101010101010101000101010101010101010101010101010100010101010101010101010101010101010001010101010101010101010101010101000000000000000000000
2200000000000000000000000000002400100101010101100101101001010101100010010101010110010110101001010110001001010101011001100101010101011000100101010101100110010101010101100010010101010110010110100101010110001001010101011001011010101010101000000000000000000000
2200000000000000000000000000002400100801010101100101010101010101100010080101010110010101010101010110001008010101011001010101010101011000100801010101100101010101010101100010080101010110010101010101010110001008010101011001010101010110011000000000000000000000
2200000000000000000000000000002400101801010101100101010101010101100010180101010110010101010101010110001018010101011001010101010101011000101801010101100101010101010101100010180101010110010101010101010110001018010101011001010101010101011000000000000000000000
2223232323232323232323232323232400100101010101100101010101010101100010010101010110010101010101010110001001010101011001010101010101011000100101010101100101010101010101100010010101010110010101010101010110001001010101011001010101010101011000000000000000000000
2200000000000000000000000000002400100101010101100101010101010101100010010101010110010101010101010110001001010101011001010101010101011000100101010101100101010101010101100010010101010110010101010101010110001001010101011001010101010101011000000000000000000000
2200150000000000000000000000002400100101010101010101010101010101100010010101010101010101010101010110001001010101010101010101010101011000100101010101010101010101010101100010010101010101010101010101010110001001010101010101010101010101011000000000000000000000
2200000000000000000000000000002400100101010101010101010101010101100010010101010101010101010101010110001001010101010101010101010101011000100101010101010101010101010101100010010101010101010101010101010110001001010101010101010101010101011000000000000000000000
2200050000000000000000000000002400100101010101010101010101010101100010010101010101010101010101010110001001010101010101010101010101011000100101010101010101010101010101100010010101010101010101010101010110001001010101010101010101010101011000000000000000000000
2200000000000000000000000000002400100101010101010101010101010101100010010101010101010101010101010110001001010101010101010101010101011000100101010101010101010101010101100010010101010101010101010101010110001001010101010101010101010101011000000000000000000000
2200040000000000000000000000002400100101010101010101010101010101100010010101010101010101010101010110001001010101010101010101010101011000100101010101010101010101010101100010010101010101010101010101010110001001010101010101010101010101011000000000000000000000
3233333333333333333333333333333400101010101010101010101010101010100010101010101010101010101010101010001010101010101010101010101010101000101010101010101010101010101010100010101010101010101010101010101010001010101010101010101010101010101000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101000101010101010101010101010101010100010101010101010101010101010101010001010101010101010101010101010101000101010101010101010101010101010100010101010101010101010101010101010001213131313131313131313131313131400000000000000000000
1001010101011001100101010110011000100101010101100110010101010101100010010101010110010110100101010110001001010101011001010101010101011000100101010101100110010101010101100010010101010110010110100101010110002202000000000000000000000000002400000000000000000000
1008010101011001101010101010011000100801010101100101010101010101100010080101010110010101010101010110001008010101011001010101010101011000100801010101100101010101010101100010080101010110010101010101010110002200000000000000000000000000002400000000000000000000
1018010101011001010101010101011000101801010101100101010101010101100010180101010110010101010101010110001018010101011001010101010101011000101801010101100101010101010101100010180101010110010101010101010110002200000000000000000000000000002400000000000000000000
1001010101011001010101010101011000100101010101100101010101010101100010010101010110010101010101010110001001010101011001010101010101011000100101010101100101010101010101100010010101010110010101010101010110002200000000000000000000000000002400000000000000000000
1001010101010101010101010101011000100101010101100101010101010101100010010101010110010101010101010110001001010101011001010101010101011000100101010101100101010101010101100010010101010110010101010101010110002200000000000000000000000000002400000000000000000000
1001010101010101010101010101011000100101010101010101010101010101100010010101010101010101010101010110001001010101018801010101010101011000100101010101010101010101010101100010010101010101010101010101010110002200000000000000000000000000002400000000000000000000
1001010101010101010101010101011000100101010101010101010101010101100010010101010101010101010101010110001001010101010101010101010101011000100101010101010101010101010101100010010101010101010101010101010110002200000000000000000000000000002400000000000000000000
1001010101010101010101010101011000100101010101010101010101010101100010010101010101010101010101010110001001010101010101010101010101011000100101010101010101010101010101100010010101010101010101010101010110002200000000000000000000000000002400000000000000000000
1001010101010101010101010101011000100101010101010101010101010101100010010101010101010101010101010110001001010101010101010101010101011000100101010101010101010101010101100010010101010101010101010101010110002200000000000000000000000000002400000000000000000000
1001010101010101010101010101011000100101010101010101010101010101100010010101010101010101010101010110001001010101010101010101010101011000100101010101010101010101010101100010010101010101010101010101010110002200000000000000000000000000002400000000000000000000
1010101010101010101010101010101000101010101010101010101010101010100010101010101010101010101010101010001010101010101010101010101010101000101010101010101010101010101010100010101010101010101010101010101010003233333333333333333333333333333400000000000000000000
__sfx__
901e002027745277152771527715277152772527725277153071530745307353071530745307452c7352c7252c7152c7352c7352c7252c7352c7252c7352c7452c7252c7352c7452c7452c7452c7452c72500000
901e00202772527745277152771527715277152772527725277153071530745307353071530745307452c7352c7252c7152c735297352972529735297252973529745297252b7352c7452c7452c7452b7452b725
001e00200c0433f205246150c0053f10500005246150c0050c0053f300246150c0050c00500005246150c0430c0433f500246150c0050c00500005246150c0050c0003f500246150c0050c00500005246150c005
001e00200c0433f205246150c0053f10500005246150c0050c0053f300246150c0050c00500005246150c0050c0433f500246150c0050c00500005246150c0430c0433f41524615256152a6152c6153061532615
001e00000c0003f200246150c0003f11500000246150c0000c0003f300246150c0000c0000c615246150c0000c0003f515246150c0000c00000000246150c0000c0003f415246150c61518615246152461530615
301e00000313500105031050313503105031050313503105031350310503105031350310503105031350310500135031050010500135001050010500135001050013500105001050013500105001050013500105
001e00000313500105031050313503105031050313503105031350310503105031350310503105031350310500135031050010500135001050013500105001050013500135001050013500105001050013500105
641e002027012270122701227012270122b01233012330123301230012300122e0122e0122b0122b012290122e0122e0022e0122e0022e0122701226012180121d012220122e0122b0122b012290122901229012
641e00002b0122b0122b0122b0122e0122701227012270122701230012300122e0122e0122b012290122701224012220121f0121d0121b0121b012180121f0121f0121f0121f0121f0121f0121f0122401224012
001000002400024000240002400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400200005200052000520005200052000520005200052000520005200052000520005200052000520005200052000520005200052000520005200052000520005200052000520005200052000520005200000
011400000305203052030520305203052030520305203052030520305203052030520305203052030520305203052030520305203052030520305203052030520305203052030520305203052030520305203052
c514002002000020002e0122c0122c0122a2122a21227200272122c3002c3002a3002c4002a400274002c400273122c3122c3122a3122c4122a412274122c4002a4002740002000020002c4122a4122741200000
cd1400202c3002a3122a3002a3102c2112c3102c3122a300273002e3122c3002e3122c3002a300273002c300272002c2002c2002a2102c2112a210273122c3002a30027300023002730032000320003200031000
911400200c0330c0000c0030c0050c0430c0000c0000c0050c0430c0000c0000c0050c0330c0000c000246000c0330c0000c0000c0050c0530c0000c0000c0050c0333f2050c0000c0050c033000050c6230c005
771400201b60500605006053f6153f615006051b605006051b60500605371003b1003b100006051b605006051b60000605371153b1151b605006051b605006051b6001b6001b6001b600006051b6141b6141b614
791400203201232012320153201232012320153301133012330123301233012330123301531000310003100031000320003100031000310003200032000320003201531011310153201531011310123101231015
791400203201232012320153201232015330113301233012330123301233012330123300031000310003100031012310123101532011310153201131012310123200031000310003201531011310123101231015
4b14002032000320003200032000320003200033000330003300033000330000f0451102513055150451600531004150451704519034246242462424624246242460031000310003200031000310003100031000
011400200c0003f20524615246003f10500005246150c0050c0053f30024615246000c00500005246150c0000c0003f500246150c0050c00524600246150c0050c0003f500246150c0050c00500005246150c005
910c00200c0530c0000c0030c0050c0530c0000c0000c0050c0530c0000c0000c0050c0530c0000c000246000c0530c0000c0000c0050c0530c0000c0000c0050c0533f2050c0000c0050c053000050c6000c005
490c00200c0050c0050c0050c0050c6450c0050c0050c0050c0050c0050c0050c0050c6450c0050c005246050c0050c0050c0050c0050c6050c0050c0050c0050c6450c6050c6050c6450c6050c6050c6450c645
490c00200c0050c0050c0050c0050c6450c0050c0050c0050c0050c0050c0050c0050c6450c0050c005246050c0050c0050c0050c0050c6450c0050c0050c0050c0053f2050c0050c0050c645000050c6450c005
9f0c0020131250e1250e1250e1250e1250e1250e1250e125131250e1250e1250e1250e1250e1250e1250e125131250e1250e1250e1250e1250e1250e1250e125131250e1250e1250e1250e1250e1250e1250e125
9f0c00201012513125131251312513125131251312513125101251312513125131251312513125131251312510125131251312513125131251312513125131251012513125131251312513125131251312513125
010c00200005500055000550005500055000550005500055000550005500055000550005500055000550005500055000550005500055000550005500055000550005500055000550005500055000550005500055
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
71100000290551e0001e0000000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
711000001d0551e0001e0000000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
000100000e0500f050100501105014050170501b0501e0502205024050170500a050010501c0001c0001d00000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000000022905227052290522c0522c0520000200002000020000200002000020000200002010020000200002000020000200002000020000200002000020000200002000020000200002000020000200002
1b0100002702627026270262702624026200261b02614026140261402617026190261d0262102623026280262d026000060000600006000060000600006000060000600006000060000600006000060000600006
900100000e0100d0400c0400b03009030070100601003010020100101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000211102114015140271300f6300f6101c610196001761016600156100f6000c61009600076000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001b61006540065401963018630116100e6100c610096100861000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001f5302b5302e5302e5303250032500395002751027510285102a510005000050000500275102951029510005000050000500005002451024510245102751029510005000050000500005000050000500
0001000024030240301c0301c0302a2302823025210212101e2101b2101b21016210112100d2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100a2100020000200
0001000024030240301c0301c03039010390103a0103001030010300102d010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000210302703025040230301a030190100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000d740137400d7200c40031200312000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 00054643
00 01064844
01 00054643
00 01064844
00 00050702
00 01060802
00 00050702
00 01060803
02 41064145
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424145
00 41424344
01 0a0e534f
00 0b0e530f
00 0a0e0c45
00 0b0e0d52
00 0a0e1012
02 0b0e1152
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424145
00 41424145
00 41424145
00 41424145
00 41424145
01 14161957
00 14151957
00 14161917
00 14161917
00 14161918
00 14151918
00 14161917
00 14161917
00 14161918
00 14161918
00 54551918
02 54161918
00 41424344
00 41424145
00 41424145
00 41424145
00 41424344
00 41424145
00 41424145
00 41424145
00 41424145
00 41424145
00 41424145
00 41424145
00 41424145
00 41424145
00 41424145
00 41424145
00 41424145
00 41424145
00 41424145
00 41424145

