-- moo moo care (ld 51)
-- by: kory

function _init()
 level = level_title
 is_customer_pickup = false
 is_customer_dropoff = false
 doorbell_timer = 0
 global_timer = 1 -- start at 1 for log10 function
 
 player = {
  state = idle,
  x = 8*69,
  y = 8*6,
  facing_x = 0,
  facing_y = 0,
  speed = 8,
  direction = ⬇️,
  bounce = false,
  bounced = false,
  bounce_timer = 30,
  bounce_time = 40,
  bounce_counter = 0,
  down_sprite = 32,
  left_sprite = 33,
  up_sprite = 34,
  bounce_offset = 16,
  money = 50,
  money_target = 50,
  cow = nil
 }
 
 cam = {
  x = player.x-64,
  y = player.y-64
 }
 
 phone = {
  x = 8*71,
  y = 8*3,
  sprite = sprite_phone,
  is_ringing = false,
  is_ringing_sound = false,
  ring_timer = -300,
  ring_time = 300,
  ringing_timer = 0,
  ringing_time = 300,
  ring_sound_time = 60,
  ring_animate_time = 20
 }
 
 customers = {}

 
 cows = {}
 indicators = {0, 0, 0}
 poops = {}
 
 init_gate()
 music(0, 0)
end


function _update()
 if level == level_title
 then
  if btnp(🅾️) or btnp(❎)
  then
   level = level_game
  end
 elseif level == level_game
 then
	 update_globals()
	 update_player()
	 update_cows()
	 update_phone()
	 update_customers()
	end
end

function update_globals()
 global_timer += 0.1
 doorbell_timer -= 1
end


function _draw()
 cls(1)
 pal()
 
 if level == level_title
 then
  draw_title()
 elseif level == level_game
 then
	 draw_map()
	 set_actor_palt()
	 draw_poops()
	 draw_player()
	 draw_cows()
	 draw_phone()
	 draw_indicators()
	 
	 draw_customers()
	 
	 pal()
	 draw_hud()
 elseif level == level_retire
 then
  draw_retire()
 end
end

function draw_title()
 camera()
 map(0, 0, 0, 0, 16, 16)
 print("press 🅾️ or ❎ to start!", 17, 100, 7)
end

function draw_retire()
 local time_string = "you retired in: " .. flr(global_timer * 10 / 30) .. " seconds!"

 camera()
 map(0, 0, 0, 0, 16, 16)
 print("thanks for playing!", 27, 100, 7)
 print(time_string, (128-#time_string*4)/2 + 1, 107, 7)
 
end
 
function draw_hud()
 camera()
 rectfill(0, 120, 128, 128, 14)
 
 if doorbell_timer > 0
 then
 	print("ding dong!", 1, 121, 1)
 elseif phone.is_ringing_sound
 then
 	print("ring ring!", 1, 121, 1)
 else
 	print(flr(player.money_target), 1, 121, 1)
 end
 
 draw_button_hud()
end

function draw_button_hud()
 local facing_cow = get_cow(player.facing_x, player.facing_y)
 local facing_phone = nil
 
 local x_string, o_string = "    ", "    "
 
 if (player.facing_x == phone.x and player.facing_y == phone.y) or
  (player.x == phone.x and player.y == phone.y) or
  (player.x == phone.x and player.y - 16 == phone.y and player.direction == ⬆️)
 then
  facing_phone = phone
 end
 
 if player.money >= retire_price
 then
  x_string = "retire"
  o_string = "retire"
 elseif player.state == idle
 then
 	if facing_phone and phone.is_ringing
 	then
 	 x_string = "answer"
	 elseif facing_cow
	 then
	  x_string = "pet"
  elseif is_gate(player.facing_x, player.facing_y)
  then
   x_string = "destroy"
  elseif is_grass(player.facing_x, player.facing_y) and is_empty(player.facing_x, player.facing_y) and not facing_cow
	 then
	  x_string = "fence"
	 elseif not is_gate(player.facing_x, player.facing_y) and is_fence(player.facing_x, player.facing_y)
	 then
	  x_string = "destroy"
	 end
	 
	 
	 local facing_poop = get_poop(player.facing_x, player.facing_y)
   
 	if facing_phone and phone.is_ringing
 	then
 	 o_string = "answer"
 	elseif facing_cow
  then
   o_string = "grab"
  elseif facing_poop or on_poop
 	then
 	 o_string = "clean"
 	elseif is_gate(player.facing_x, player.facing_y)
  then
  	o_string = "gate"
  elseif is_fence(player.facing_x, player.facing_y)
  then
   o_string = "gate"
	 elseif is_grass(player.facing_x, player.facing_y)
	 then
	  o_string = "plant" 
	 end
 elseif player.state == move
 then
  o_string = "drop cow"
 end
 
 local hud_string = "🅾️ " .. o_string .. " ❎ " .. x_string
 local hud_width = (#hud_string + 2) * 4
 
 print(hud_string, 128-hud_width, 121, 1)
end

-- player

function update_player()
    update_money_target()
    update_bounce(player)
    update_facing()
    handle_input()
    move_player()
    update_camera()
   end
   
   function update_money_target()
    if flr(player.money) > flr(player.money_target)
    then
     player.money_target += 1
    elseif flr(player.money) < flr(player.money_target)
    then
     player.money_target -= 1
    end
   end
   
   function update_facing()
       player.facing_x, player.facing_y = player.x, player.y
       
    if (player.direction == ⬅️) player.facing_x -= 8
    if (player.direction == ➡️) player.facing_x += 8
    if (player.direction == ⬆️) player.facing_y -= 8
    if (player.direction == ⬇️) player.facing_y += 8
   end
   
   function handle_input()
    local facing_cow = get_cow(player.facing_x, player.facing_y)
    local facing_phone = nil
    
    if (player.facing_x == phone.x and player.facing_y == phone.y) or
     (player.x == phone.x and player.y == phone.y) or
     (player.x == phone.x and player.y - 16 == phone.y and player.direction == ⬆️)
    then
     facing_phone = phone
    end
    
    if player.money >= retire_price
    then
     if btnp(🅾️) or btnp(❎)
     then
      level = level_retire
     end
    end
    if player.state == idle
    then 
     if btnp(❎)
     then
         if facing_phone and phone.is_ringing
         then
          update_phone_stop_ringing()
          queue_customer()
            elseif facing_cow
            then
             spawn_indicator(facing_cow)
             on_pet_cow(facing_cow)
         elseif is_gate(player.facing_x, player.facing_y)
         then
          destroy_gate(player.facing_x, player.facing_y)
         elseif is_grass(player.facing_x, player.facing_y) and is_empty(player.facing_x, player.facing_y) and not facing_cow
            then
             if player.money >= fence_price
             then 
              if build_fence(player.facing_x, player.facing_y)
              then
                  player.money -= fence_price
                 end
             end
            elseif not is_gate(player.facing_x, player.facing_y) and is_fence(player.facing_x, player.facing_y)
            then
             destroy_fence(player.facing_x, player.facing_y)
            end
        elseif btnp(🅾️)
        then
         local on_poop = get_poop(player.x, player.y)
         local facing_poop = get_poop(player.facing_x, player.facing_y)
          
         if facing_phone and phone.is_ringing
         then
          update_phone_stop_ringing()
          queue_customer()
            elseif facing_cow
         then
          player.state = move
          facing_cow.state = move
          facing_cow.bounce_counter = 0
          player.cow = facing_cow
         elseif facing_poop or on_poop
            then
             if (facing_poop) delete_poop(facing_poop)
       if (on_poop) delete_poop(on_poop)
         elseif is_gate(player.facing_x, player.facing_y)
         then
             flip_gate(player.facing_x, player.facing_y)
         elseif is_fence(player.facing_x, player.facing_y)
         then
          if player.money >= gate_price
          then
              if build_gate(player.facing_x, player.facing_y)
                       then
                        player.money -= gate_price
                       end
             end
            elseif is_grass(player.facing_x, player.facing_y)
            then
             if not is_fully_grown(player.facing_x, player.facing_y)
             then
              player.money -= grass_price
              grow_grass(player.facing_x, player.facing_y)
             end 
            end
        end
    elseif player.state == move
    then
     if btnp(🅾️)
     then
      player.state = idle
      player.cow.state = idle
      player.cow = nil
     end
    end
   end
   
   function move_player()
    local x, y = player.x, player.y
    local cx, cy = 0, 0
    
    if (player.cow) cx, cy = player.cow.x, player.cow.y
   
    if btnp(⬅️)
    then
     x -= player.speed
     cx -= player.speed
     if (player.state != move) player.direction = ⬅️
    elseif btnp(➡️)
    then
     x += player.speed
     cx += player.speed
     if (player.state != move) player.direction = ➡️
    elseif btnp(⬆️)
    then
     y -= player.speed
     cy -= player.speed
     if (player.state != move) player.direction = ⬆️
    elseif btnp(⬇️)
    then
     y += player.speed
     cy += player.speed
     if (player.state != move) player.direction = ⬇️
    end
    
    if player.state == idle
    then
     if not is_solid(x, y) and not get_cow(x, y)
     then
      if x != player.x or y != player.y
      then
       play_sfx(sfx_walk)
      end
      player.x, player.y = x, y
     end
    elseif player.state == move
    then 
     if not is_solid(x, y) and (not get_cow(x, y) or get_cow(x, y) == player.cow) and not is_solid(cx, cy) and not get_cow(cx, cy)
     then
      if x != player.x or y != player.y
      then
       play_sfx(sfx_walk)
      end
      
      player.x, player.y = x, y
      player.cow.x, player.cow.y = cx, cy
     end
    end
   end
   
   function update_camera()
    if player.x < cam.x + 32
    then
     cam.x = player.x - 32
    elseif player.x > cam.x + 96
    then
     cam.x = player.x - 96
    end
    
    if player.y < cam.y + 32
    then
     cam.y = player.y - 32
    elseif player.y > cam.y + 96
    then
     cam.y = player.y - 96
    end
    
    if (cam.x < 128) cam.x = 128
    if (cam.y < 0) cam.y = 0
    if (cam.x > 8*112) cam.x = 8*112
    if (cam.y > 8*8) cam.y = 8*8 
    
    camera(cam.x, cam.y)
   end
   
   function draw_player()
    local sprite, flip_x = 0, false
    
    if (player.direction == ⬅️) sprite = player.left_sprite
    if (player.direction == ➡️) sprite, flip_x = player.left_sprite, true
    if (player.direction == ⬆️) sprite = player.up_sprite
    if (player.direction == ⬇️) sprite = player.down_sprite
      
    if (player.bounce) sprite += player.bounce_offset
    
    spr(sprite, player.x, player.y, 1, 1, flip_x)
   end

-- actors

function update_bounce(actor)
    if actor.state == idle
    then 
        actor.bounce_timer += 1
        
        actor.bounced = false
        
        if actor.bounce_timer > actor.bounce_time
        then
         actor.bounce = not actor.bounce
         actor.bounce_timer = 0
         actor.bounced = true
         
         actor.bounce_counter += 0.5
        end
    else
     actor.bounce_timer = 0
     actor.bounced = false
     actor.bounce = false
    end
   end
   
   function set_actor_palt()
    palt(0b0001000000000000)
   end
   
   function spawn_poop(cow)
    local poop = {
     id = #poops+1,
     x = cow.x,
     y = cow.y
    }
    
    poops[#poops+1] = poop
   end
   
   function delete_poop(poop)
    poops[#poops].id = poop.id
    poops[poop.id] = poops[#poops]
    poops[#poops] = nil
   end
   
   function get_poop(x, y)
       local i, poop
   
    for i, poop in pairs(poops) do
     if (poop.x == x and poop.y == y) return poop
    end
    
    return nil
   end
   
   function draw_poops()
    for i, poop in pairs(poops) do
     spr(sprite_poop, poop.x, poop.y)
    end
   end
   
   function spawn_indicator(actor)
    local indicator = {
     actor = actor,
     timer = 0,
     delete_time = indicator_delete_time
    }
    
    indicators[get_indicator_id()] = indicator
   end
   
   function get_indicator_id()
    local i, indicator
    
    for i,indicator in pairs(indicators) do
     if (indicator == 0) return i
    end
    
    for i = 1,#indicators-1 do
     indicators[i+1] = indicators[i]
    end
    
    return 1
   end
   
   function draw_indicators()
    local i, indicator
    
    for i, indicator in pairs(indicators) do
     if indicator != 0
     then
         local x, y
         
         indicator.timer += 1
         
         x = indicator.actor.x - 4
         y = indicator.actor.y - 16 - flr(indicator.timer / indicator_float_time)
         
         spr(sprite_indicator, x, y, 2, 2)
         spr(get_happiness_sprite(indicator.actor.happiness), x+4, y+1)
         
         if (indicator.timer >= indicator.delete_time) indicators[i] = 0
     end
    end
   end
   
   function get_happiness_sprite(happiness)
    if (happiness > 15) return sprite_full_happy
    if (happiness > 9.5) return sprite_kinda_happy
    if (happiness > 4) return sprite_meh_happy
    return sprite_not_happy
   end
   
   function spawn_cow(x, y)
    local cow = {
     id = get_cow_id(),
     state = idle,
     x = x,
     y = y,
     flip_x = rnd(false_true),
     pattern = flr(rnd(9)+0.5),
     horns = true,
     sprite = sprite_cow,
     
     bounce = false,
     bounced = false,
     bounce_timer = 0,
     bounce_time = rnd(cow_bounce_time) + cow_bounce_time,
     bounce_offset = cow_bounce_offset,
     bounce_counter = 0,
     
     eat = false,
     eat_count = cow_eat_count,
     move_count = cow_move_count,
     moved = false,
     
     eat_timer = 0,
     eat_time = cow_eat_time,
     
     happiness = cow_happiness_max,
     moo_count = flr(rnd(cow_moo_count)) + cow_moo_count
    }
    
    cows[cow.id] = cow
    
    return cow
   end
   
   
   function get_cow_id()
    local i
    
    for i = 1,#cows do
     if (cows[i] == 0) return i
    end
    
    return #cows + 1
   end
   
   function get_cow(x, y)
    local i, cow
    
    for i, cow in pairs(cows) do
     if cow != 0
     then
         if (cow.x == x and cow.y == y) return cow
     end
    end
    
    return nil
   end
   
   function update_cows()
    local i, cow
    
    for i, cow in pairs(cows) do
     if cow != 0
     then
         update_bounce(cow)
            update_cow_eat(cow)
            update_cow_move(cow)
            update_cow_poops(cow)
            update_cow_moo(cow)
        end
    end
   end
   
   function update_cow_eat(cow)
    if cow.bounce_counter != 0 and cow.bounce_counter % cow.eat_count == 0
    then
     cow.eat = true
    end
    
    if cow.eat
    then
        if cow.eat_timer == 0
        then
         local poop = get_poop(cow.x, cow.y)
        
         play_sfx(cow_eat)
         if poop
         then
          cow.happiness += cow_eat_poop_penalty
         end
         
         if is_any_grown(cow.x, cow.y)
         then
       shrink_grass(cow.x, cow.y)
       
       if not poop
       then
        cow.happiness += cow_eat_grass_increase
       end	  
         end
        end
    
     cow.sprite = sprite_cow_eat
     cow.eat_timer += 1
     
     if cow.eat_timer >= cow.eat_time
     then
      cow.eat = false
      cow.sprite = sprite_cow
      cow.eat_timer = 0
     end
    end
    
    if cow.state == move
    then
     cow.eat = false
     cow.sprite = sprite_cow
     cow.eat_timer = 0
    end
   end
   
   function update_cow_move(cow)
    local x, y = cow.x, cow.y
    
    if cow.state == idle and cow.bounce_counter != 0 and cow.bounce_counter % cow.move_count == 0
    then
        if (cow.moved) return
        
        cow.moved = true
    
     while x == cow.x and y == cow.y do
         x = cow.x + player.speed * rnd(signs)
         y = cow.y + player.speed * rnd(signs)
     end  
     
     if get_cow(x, y)
     then
      cow.happiness += cow_bump_penalty
     elseif player.x == x and player.y == y
     then
   --   printh("moving to player")
     elseif not is_solid(x, y)
     then
      cow.x = x
      cow.y = y
     end
    else
     cow.moved = false
    end
   end
   
   function update_cow_poops(cow)
    if cow.state == idle and cow.bounce_counter != 0 and cow.bounce_counter % cow_poop_count == 0
    then
     if (cow.bounced) spawn_poop(cow)
    end
   end
   
   function update_cow_moo(cow)
    if cow.state == idle and cow.bounce_counter != 0 and cow.bounce_counter % cow.moo_count == 0
    then
     if (cow.bounced) play_sfx(sfx_moo)
    end
   end
   
   function draw_cows()
    local sprite, i, cow, pattern_x, pattern_y, pattern_target_x, pattern_target_y, horns_x, horns_y
    
    for i, cow in pairs(cows) do
     draw_cow(cow)
    end
   end
   
   function draw_cow(cow)
    sprite = cow.sprite
    
    pattern_x = (cow.pattern % 2) * cow_pattern_width
    pattern_y = flr(cow.pattern / 2) * cow_pattern_height
    
    pattern_target_y = cow.y + cow_pattern_target_y_offset
   
    if (cow.bounce) 
    then
     sprite += cow.bounce_offset
     pattern_target_y += 1
    end
    
    if cow.flip_x
    then 
     pattern_target_x = cow.x
    else
     pattern_target_x = cow.x + cow_pattern_target_x_offset
    end
    
    spr(sprite, cow.x, cow.y, 1, 1, cow.flip_x)
    sspr(pattern_x, pattern_y + cow_pattern_sprite_y_offset, cow_pattern_width, cow_pattern_height, pattern_target_x, pattern_target_y)
   
    if cow.horns
    then
     if not cow.eat
     then 
      if cow.flip_x and cow.bounce
      then
          line(cow.x + 5, cow.y + 2, cow.x + 5, cow.y + 1, color_cow_horns)
      elseif cow.flip_x
      then
          line(cow.x + 5, cow.y + 1, cow.x + 5, cow.y, color_cow_horns)
      elseif cow.bounce
      then
          line(cow.x + 2, cow.y + 2, cow.x + 2, cow.y + 1, color_cow_horns)
      else
          line(cow.x + 2, cow.y + 1, cow.x + 2, cow.y, color_cow_horns)
      end
     else
      if cow.flip_x and cow.bounce
      then
       line(cow.x+7, cow.y+5, cow.x+8, cow.y+5, color_cow_horns)
      elseif cow.flip_x
      then
       line(cow.x+7, cow.y+4, cow.x+8, cow.y+4, color_cow_horns)
      elseif cow.bounce
      then
       line(cow.x, cow.y+5, cow.x-1, cow.y+5, color_cow_horns)
      else
       line(cow.x, cow.y+4, cow.x-1, cow.y+4, color_cow_horns)
      end
     end
    end
   end
   
   function on_pet_cow(cow)
    if cow.state == idle
    then
        cow.happiness += cow_pet_increase
        play_sfx(sfx_moo)
    end
   end

-- world

function draw_map()
    map(flr(cam.x/8), flr(cam.y/8), cam.x, cam.y, 16, 16)
   end
   
   function mgetw(x, y)
    return mget(flr(x/8), flr(y/8))
   end
   
   function msetw(x, y, sprite)
    return mset(flr(x/8), flr(y/8), sprite)
   end
   
   function is_inbounds(x, y)
    return x >= 128 and x < 8*128 and y >= 0 and y < 8*23
   end
   
   function is_flag(x, y, flag)
    local sprite = mgetw(x, y)
    
    return fget(sprite, flag)
   end
   
   function is_empty(x, y)
    local sprite = mgetw(x, y)
    
    return fget(sprite) == 0x80
   end
   
   function is_fence(x, y)
       return not is_inbounds(x, y) or is_flag(x, y, flag_fence)
   end
   
   function is_gate(x, y)
    return is_flag(x, y, flag_gate)
   end
   
   function is_solid(x, y)
    return not is_inbounds(x, y) or is_flag(x, y, flag_solid)
   end
   
   function is_grass(x, y)
    return is_flag(x, y, flag_grass)
   end
   
   function is_any_grown(x, y)
    return is_grass(x, y) and mgetw(x, y) > sprite_ground_start
   end
   
   function is_fully_grown(x, y)
    return mgetw(x, y) == sprite_ground_end
   end
   
   function is_fence_or_gate(x, y)
    return is_fence(x, y) or is_gate(x, y)
   end
   
   function is_fence_not_gate(x, y)
    return is_fence(x, y) and not is_gate(x, y)
   end
   
   function grow_grass(x, y)
    local grass_level = mgetw(x, y)
    local next_level = clamp(grass_level+1, sprite_ground_start, sprite_ground_end)
    msetw(x, y, next_level)
   end
   
   function shrink_grass(x, y)
    local grass_level = mgetw(x, y)
    local next_level = clamp(grass_level-1, sprite_ground_start, sprite_ground_end)
    msetw(x, y, next_level)
   end
   
   function flip_gate(x, y)
    local sprite = mgetw(x, y)
    local sprite_flip = gate_flip[sprite]
    local other_x, other_y = x, y
    
    if sprite == gate_left_closed or sprite == gate_left_open
    then
     other_x += 8
    elseif sprite == gate_right_closed or sprite == gate_right_open
    then
     other_x -= 8
    elseif sprite == gate_up_closed or sprite == gate_up_open
    then
     other_y += 8
    elseif sprite == gate_down_closed or sprite == gate_down_open
    then
     other_y -= 8
    end
    
    local other_sprite = mgetw(other_x, other_y)
    local other_sprite_flip = gate_flip[other_sprite]
    
    if other_x != x or other_y != y
    then
     msetw(x, y, sprite_flip)
     msetw(other_x, other_y, other_sprite_flip)
     
     if is_gate_open(sprite)
     then
      play_sfx(sfx_gate_close)
     else
      play_sfx(sfx_gate_open)
     end
    end
   end
   
   function is_gate_open(sprite)
    return sprite == gate_up_open or 
     sprite == gate_down_open or
     sprite == gate_left_open or
     sprite == gate_right_open
   end
   
   function build_fence(x, y)
    msetw(x, y, sprite_fence_start)
    
    update_fence(x, y)
    update_fence(x-8, y)
    update_fence(x+8, y)
    update_fence(x, y-8)
    update_fence(x, y+8) 
    
   return true
   end
   
   function destroy_fence(x, y)
    msetw(x, y, sprite_ground_start)
   
    update_fence(x, y)
    update_fence(x-8, y)
    update_fence(x+8, y)
    update_fence(x, y-8)
    update_fence(x, y+8)
    
    return true
   end
   
   function build_gate(x, y)
    if (is_gate(x, y) or not is_fence(x, y)) return false
   
    if is_fence_not_gate(x, y-8)
    then
     msetw(x, y-8, gate_up_closed)
     msetw(x, y, gate_down_closed)
    elseif is_fence_not_gate(x, y+8)
    then
     msetw(x, y, gate_up_closed)
     msetw(x, y+8, gate_down_closed)
    elseif is_fence_not_gate(x-8, y)
    then
     msetw(x-8, y, gate_left_closed)
     msetw(x, y, gate_right_closed)
    elseif is_fence_not_gate(x+8, y)
    then
     msetw(x, y, gate_left_closed)
     msetw(x+8, y, gate_right_closed)
    else
     return false
    end  
    
    for i=-2,2 do
     for j=-2,2 do
      update_fence(x+i*8, y+j*8)
     end
    end
    
    return true
   end
   
   function destroy_gate(x, y)
    if (not is_gate(x, y)) return false
   
    local gate = mgetw(x, y)
   
    if (gate == gate_down_open or gate == gate_down_closed) and 
        is_gate(x, y-8)
    then
     msetw(x, y-8, sprite_ground_start)
     msetw(x, y, sprite_ground_start)
    elseif (gate == gate_up_open or gate == gate_up_closed) and 
        is_gate(x, y+8)
    then
     msetw(x, y, sprite_ground_start)
     msetw(x, y+8, sprite_ground_start)
    elseif (gate == gate_right_open or gate == gate_right_closed) and 
        is_gate(x-8, y)
    then
     msetw(x-8, y, sprite_ground_start)
     msetw(x, y, sprite_ground_start)
    elseif (gate == gate_left_open or gate == gate_left_closed) and 
        is_gate(x+8, y)
    then
     msetw(x, y, sprite_ground_start)
     msetw(x+8, y, sprite_ground_start)
    else
     msetw(x, y, sprite_ground_start)
    end  
    
    for i=-2,2 do
     for j=-2,2 do
      update_fence(x+i*8, y+j*8)
     end
    end
    
    return true
   end
   
   function update_fence(x, y)
    local offset = 0
    
    if is_fence(x, y) and not is_gate(x, y)
    then
     if (is_fence_or_gate(x, y-8)) offset += 1
     if (is_fence_or_gate(x+8, y)) offset += 2
     if (is_fence_or_gate(x, y+8)) offset += 4
     if (is_fence_or_gate(x-8, y)) offset += 8
    
     msetw(x, y, sprite_fence_start + offset)
    end
   end

--constants

false_true = {false, true}
signs = {-1, 0, 1}

idle = 0
move = 1
stay = 2

level_title = 0
level_game = 1
level_retire = 2

doorbell_time = 40

customer_x = 68*8
customer_y = 2*8

sprite_phone = 43

fence_price = 1
gate_price = 3 --costs two fence to make a gate
grass_price = 2
retire_price = 500

sprite_fence_start = 16
sprite_ground_start = 5
sprite_ground_end = 8

sprite_full_happy = 37
sprite_kinda_happy = 38
sprite_meh_happy = 53
sprite_not_happy = 54

sprite_poop = 9

sprite_indicator = 35
indicator_delete_time = 99
indicator_float_time = 20

sprite_cow = 1
sprite_cow_eat = 3
color_cow_horns = 6
cow_bounce_offset = 1
cow_bounce_time = 15
cow_eat_count = 4
cow_eat_time = 60
cow_move_count = 1
cow_poop_count = 7.5
cow_moo_count = 7

cow_pattern_width = 6
cow_pattern_height = 3
cow_pattern_sprite_y_offset = 32
cow_pattern_target_x_offset = 2
cow_pattern_target_y_offset = 3
cow_happiness_max = 20
cow_eat_poop_penalty = -2.0
cow_bump_penalty = -5
cow_pet_increase = 0.3
cow_eat_grass_increase = 15.0

flag_fence = 0
flag_gate = 1
flag_solid = 2
flag_grass = 7

gate_left_closed = 39
gate_right_closed = 40
gate_left_open = 55
gate_right_open = 56

gate_up_closed = 41
gate_down_closed = 57
gate_up_open = 42
gate_down_open = 58

function init_gate()
 gate_flip = {}
 
	gate_flip[gate_left_closed] = gate_left_open
	gate_flip[gate_right_closed] = gate_right_open
	gate_flip[gate_left_open] = gate_left_closed
	gate_flip[gate_right_open] = gate_right_closed
	
	gate_flip[gate_up_closed] = gate_up_open
	gate_flip[gate_down_closed] = gate_down_open
	gate_flip[gate_up_open] = gate_up_closed
	gate_flip[gate_down_open] = gate_down_closed
end
-- misc

function get_random_pal()
    local p = {}
    
    for i = 1,16 do
     p[i] = flr(rnd(15.99))
    end
    
    return p
   end
   
   function shallow_copy_table(table)
    local t = {}
    
    for key, value in pairs(table) do
     t[key] = value
    end
    
    return t
   end
   
   function update_phone()
    phone.ring_timer += 1
    
    if phone.ring_timer >= phone.ring_time
    then
     local ringing_sound_timer = phone.ringing_timer % phone.ring_sound_time
        phone.ringing_timer += 1
     phone.is_ringing = true
     
     if ringing_sound_timer == 0
     then
      play_sfx(sfx_phone)
     end
     
     if ringing_sound_timer < phone.ring_animate_time
     then
      phone.is_ringing_sound = true
         phone.sprite = sprite_phone + flr(rnd(2.99))
     else
      phone.is_ringing_sound = false
      phone.sprite = sprite_phone
     end
     
     if phone.ringing_timer >= phone.ringing_time
     then
      update_phone_stop_ringing()
     end
    end
   end
   
   function update_phone_stop_ringing()
    phone.ring_timer = 0
    phone.ringing_timer = 0
    phone.sprite = sprite_phone
    phone.is_ringing = false
    phone.is_ringing_sound = false
   end
   
   function queue_customer()
    local customer = {
     happiness = 0,
     wait_timer = 0,
     wait_time = get_wait_time(),
     return_time = 30*30,
     is_active = false,
     is_waiting_dropoff = false,
     has_dropped_off = false,
     pall = get_random_pal(),
     cow_copy = nil,
     delete = false
    }
    
   
    customers[#customers+1] = customer
   end
   
   function get_wait_time()
    local wait_time_raw = 10 - 2.85 * log10(global_timer)
    local wait_time_seconds = clamp(wait_time_raw, 3, 10)
    local wait_time_frames = wait_time_seconds * 30
    return wait_time_frames
   end
   
   function get_wait_penalty(timer, t)
    if timer > t
    then
        return -0.02 * (timer - t) + 5
       else
        return 5
       end
   end
   
   function update_customers()
    local i, customer, cow
       local delete = {}
   
    scan_dropoff_customers()
    activate_customers()
   
    for i, customer in pairs(customers) do
     customer.wait_timer += 1
     
     if customer.is_waiting_dropoff
     then
      local facing_x = customer_x
      local facing_y = customer_y + 8
         local cow = get_cow(facing_x, facing_y)
          
      if cow and cow.state == move
      then   
                   customer.happiness += get_wait_penalty(customer.wait_timer, customer.wait_time)
       customer.is_waiting_dropoff = false
       customer.has_dropped_off = true
                   customer.wait_timer = 0
      end
     end
     
     if customer.wait_timer >= customer.return_time
     then 
      local facing_x = customer_x + 8
      local facing_y = customer_y + 8
         local cow = get_cow(facing_x, facing_y)
           
      if customer.is_active and cow and cow.state == idle and is_customers_cow(customer, cow)
      then
       customer.happiness += get_wait_penalty(customer.wait_timer, customer.return_time)
       
       printh(customer.happiness .. " " .. cows[cow.id].happiness)
       
       if customer.happiness > -7
       then     
           player.money += clamp(customer.happiness + cows[cow.id].happiness, 0, 100)	
          end
          
       cows[cow.id] = nil
       customer.delete = true
      end
     end
     
     if customer.delete
     then
      delete[#delete+1] = i
     end
    end
    
    for i = #delete, 1, -1 do
     local id = delete[i]
     
     customers[id] = customers[#customers]
     customers[#customers] = nil
    end
   end
   
   function scan_dropoff_customers()
       if not is_any_customer_dropoff()
    then
     for i, customer in pairs(customers) do
      if not customer.has_dropped_off and customer.wait_timer >= customer.wait_time
      then
             play_sfx(sfx_customer_pickup)
       is_customer_dropoff = true
       customer.is_waiting_dropoff = true
       
             local cow = spawn_cow(customer_x, customer_y + 8)
             cow.state = stay
             customer.cow_copy = shallow_copy_table(cow)
             customer.cow_copy.x = customer_x+8
             customer.cow_copy.y = customer_y-16+2
       return
      end
     end
    
        is_customer_dropoff = false 
    end
   end
   
   function is_any_customer_dropoff()
       for i, customer in pairs(customers) do
     if (customer.is_waiting_dropoff) return true
    end
    
    return false
   end
   
   function activate_customers()
    if not is_any_customer_active()
    then
     for i, customer in pairs(customers) do
      if customer.has_dropped_off and customer.wait_timer >= customer.return_time
      then
       is_customer_pickup = true
       customer.is_active = true
       play_sfx(sfx_customer_pickup)
       return
      end
     end
    
        is_customer_pickup = false 
    end
   end
   
   function is_any_customer_active()
    for i, customer in pairs(customers) do
     if (customer.is_active) return true
    end
    
    return false
   end
   
   function is_customers_cow(customer, cow)
    return customer.cow_copy.pattern == cow.pattern and 
     customer.cow_copy.horns == cow.horns
   end
   
   function draw_phone()
    spr(phone.sprite, phone.x, phone.y)
   end
   
   function draw_customers()
    local i, customer
   
    for i, customer in pairs(customers) do
        pal(customer.pall)
        
        if customer.is_waiting_dropoff
        then
            spr(player.down_sprite, customer_x, customer_y)
           end
            
           if customer.is_active
        then
         spr(player.down_sprite, customer_x+8, customer_y)
         pal()
         set_actor_palt()
         spr(sprite_indicator, customer_x+8-4, customer_y-16, 2, 2)
         draw_cow(customer.cow_copy)
        end
    end
   end

-- sfx

sfx_walk = 15
sfx_phone = 16
sfx_gate_open = 17
sfx_gate_close = 18
sfx_moo = 19
sfx_eat = 20
sfx_customer_pickup = 21

function play_sfx(id)
 if id == nil
 then
  return
 end

 if id == sfx_customer_pickup
 then
  doorbell_timer = doorbell_time
 
  sfx(-1, 3)
  sfx(id, 3)
  return
 end
 
 if doorbell_timer > 0
 then
	 sfx(id, 2)
 elseif id == sfx_phone
 then 
  sfx(-1, 3)
  sfx(sfx_phone, 3)
 elseif phone.is_ringing_sound
 then
  sfx(id, 2)
 else
  sfx(id, 3)
 end
end
-- math

log10_table = {
    0, 0.3, 0.475,
    0.6, 0.7, 0.775,
    0.8375, 0.9, 0.95, 1
   }
   
   function log10(n)
    if (n < 1) return nil
    local t = 0
    while n > 10 do
     n /= 10
     t += 1
    end
    return log10_table[flr(n)] + t
   end
   
   function clamp(a, b, c)
    if a >= b
    then
     if a <= c
     then
      return a
     else
      return c
     end
    else
     return b
    end
   end