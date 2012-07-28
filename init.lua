-- painting - in-game painting for minetest-c55

-- THIS MOD CODE AND TEXTURES LICENSED 
--            <3 TO YOU <3
--    UNDER TERMS OF GPL LICENSE

-- 2012 obneq aka jin xi

-- a picture is drawn using a node(box) to draw the supporting canvas
-- and an entity which has the painting as its texture.
-- this texture is created by minetest-c55's internal image
-- compositing engine (see tile.cpp).

dofile(minetest.get_modpath("painting").."/crafts.lua")

textures = {
   white = "white.png", yellow = "yellow.png", 
   orange = "orange.png", red = "red.png", 
   violet = "violet.png", blue = "blue.png", 
   green = "green.png", magenta = "pink.png", 
   cyan = "cyan.png", lightgrey = "lightgrey.png",
   darkgrey = "darkgrey.png", black = "black.png" 
}   

res = 16
thickness = 0.1

-- picture node
picbox = {
   type = "fixed",
   fixed = { -0.5, -0.5, 0.5, 0.5, 0.5, 0.5 - thickness }
}

picnode =  {                                                    
   description = 'pic',                          
   tiles = { "white.png" },
   inventory_image = "painted.png",
   drawtype = "nodebox",
   sunlight_propagates = true,
   paramtype = 'light',
   paramtype2 = "facedir",
   node_box = picbox,
   selection_box = picbox,
   groups = { snappy = 2, choppy = 2, oddly_breakable_by_hand = 2 },
   
   --handle that right below, don't drop anything
   drop = "",
   
   after_dig_node=function(pos, oldnode, oldmetadata, digger)
      --find and remove the entity
      local objects = minetest.env:get_objects_inside_radius(pos, 0.5)
      for _, e in ipairs(objects) do
         if e:get_luaentity().name == "painting:picent" then
            e:remove()
         end
      end
      
      --put picture data back into inventory item
      local data = oldmetadata.fields["painting:picturedata"]
      local item = { name = "painting:paintedcanvas", count = 1, metadata = data } 
      digger:get_inventory():add_item("main", item)
   end
}

-- picture texture entity
picent = {
   collisionbox = { 0,0,0,0,0,0 },
   visual = "upright_sprite",
   textures = { "white.png" },

   on_activate = function(self, staticdata)
      local pos = self.object:getpos()
      local meta = minetest.env:get_meta(pos)
      local data = meta:get_string("painting:picturedata")

      if not data then return end
      data = minetest.deserialize(data)
      data = to_imagestring(data)
      self.object:set_properties({textures = { data }})
   end
}

--paintedcanvas picture inventory item
paintedcanvas = {
   inventory_image = "painted.png",
   stack_max = 1,
   
   on_place = function(itemstack, placer, pointed_thing)
      local data = itemstack:get_metadata()

      --place node
      local placerpos = placer:getpos()
      local pos = pointed_thing.above
      local dir = {x = pos.x - placerpos.x, y = pos.y - placerpos.y, z = pos.z - placerpos.z}
      local fd = minetest.dir_to_facedir(dir)

      local pic = minetest.env:add_node(pos, { name = "painting:pic",
                                               param2 = fd,
                                               paramtype2 = 'none' })
      
      local meta = minetest.env:get_meta(pos)
      meta:set_string("painting:picturedata", data)

      --and entity
      local dirs = {[0] = {x=0, z=1},
                    [1] = {x=1, z=0},
                    [2] = {x=0, z=-1},
                    [3] = {x=-1, z=0}}
      local dir=dirs[fd]
      local off = 0.5-thickness-0.01
      
      local np = {
         x = pos.x+dir.x*off,
         y = pos.y,
         z = pos.z+dir.z*off}
      
      data = minetest.deserialize(itemstack:get_metadata())
      data = to_imagestring(data)
      
      local p = minetest.env:add_entity(np, "painting:picent"):get_luaentity()
      p.object:set_properties({textures = { data }})
      p.object:setyaw(math.pi*fd/-2)
      
      return ItemStack("")
   end
}

--canvas inventory item
canvas = {
        inventory_image = "default_paper.png",
        stack_max = 99,
}

--canvas for drawing
canvasbox = {
   type = "fixed",
   fixed = { -0.5, -0.5, 0.0, 0.5, 0.5, thickness }
}

canvasnode = {
   description = 'canvas',
   tiles = { "white.png" },
   inventory_image = "painted.png",
   drawtype = "nodebox",
   sunlight_propagates = true,
   paramtype = 'light',
   paramtype2 = "facedir",
   node_box = canvasbox,
   selection_box = canvasbox,
   groups = { snappy = 2, choppy = 2, oddly_breakable_by_hand = 2 },

   drop = "",
      
   can_dig = function ()
      return true
   end,
   
   on_construct = function(pos)
      local node =  minetest.env:get_node(pos)
      local fd = node.param2
      
      for y = 0, res-1 do
         for x = 0, res-1 do
            local xstep = x/res
            local off = 1/(res*2)
            
            local boff = 0.01-off
            
            local dirs2 = {
               [0] = { x =-0.5 + off + xstep, z = 0 - boff },
               [1] = { x = 0 - boff, z = 0.5 - off - xstep },
               [2] = { x = 0.5 - off - xstep, z = 0 + boff },
               [3] = { x = 0 + boff, z =-0.5 + off + xstep },
            }
            
            local dir = dirs2[fd]
            
            local np = {x = pos.x + dir.x,
                          y = pos.y + (0.5-1/(res*2)) - y/res,
                          z = pos.z + dir.z}
            
            local p = "painting:pixel_white"
            p =  minetest.env:add_entity(np, p):get_luaentity()
            p.object:setyaw(math.pi*fd/-2)
            p.pos={x=x, y=y}
            p.name="easel"
         end
      end
   end,
   
   after_dig_node=function(pos, oldnode, oldmetadata, digger)
      local data = {}
      for y=0,res-1 do
         for x=0, res-1 do               
            table.insert(data, grid[x][y] )
         end
      end
      
      local easel = { x = pos.x, y = pos.y - 1, z = pos.z }
      minetest.env:get_meta(easel):set_int("has_canvas", 0) 

      local item = { name = "painting:paintedcanvas", count = 1, metadata = minetest.serialize(data) }
      digger:get_inventory():add_item("main", item)
      
      --clean up pixels
      initgrid()
      local objects = minetest.env:get_objects_inside_radius(pos, 1)
      for _, e in ipairs(objects) do
         if e:get_luaentity().name == "easel" then
            e:remove()
         end
      end
   end
}

-- easel
easelbox = {
   type="fixed",
   fixed = {
      --feet
      {-0.4, -0.5, -0.5, -0.3, -0.4, 0.5 },
      { 0.3, -0.5, -0.5,  0.4, -0.4, 0.5 },
      --legs
      {-0.4, -0.4, 0.1, -0.3, 1.5, 0.2 },            
      { 0.3, -0.4, 0.1,  0.4, 1.5, 0.2 },
      --shelf
      {-0.5, 0.35, -0.3, 0.5, 0.45, 0.1 }
   }
}

easel = {
   description = 'easel',
   tiles = { "default_wood.png" },
   drawtype = "nodebox",
   sunlight_propagates = true,
   paramtype = 'light',
   paramtype2 = "facedir",
   node_box = easelbox,
   selection_box = easelbox,
   
   groups = { snappy = 2, choppy = 2, oddly_breakable_by_hand = 2 },
   
   on_punch = function(pos, node, player)
      local wielded = player:get_wielded_item():get_name()
      if wielded ~= 'painting:canvas' then
         return
      end    
      local meta = minetest.env:get_meta(pos)       
      local np  = { x = pos.x, y = pos.y+1, z = pos.z }
      
      if minetest.env:get_node(np).name == "air" then 
         minetest.env:add_node(np, { name = "painting:canvasnode",
                                     param2 = node["param2"],
                                     paramtype2 = 'none' })
      end
      
      meta:set_int("has_canvas", 1)
      local itemstack = ItemStack("painting:canvas")
      player:get_inventory():remove_item("main", itemstack)   
   end,
   
   can_dig = function(pos,player)
      local meta = minetest.env:get_meta(pos)
      local inv = meta:get_inventory()
      
      if meta:get_int("has_canvas") == 0 then
         return true
      end
      return false
   end
}

--pixel and brushes
local c = 1/(res*2)
local p = "white.png"

pixel = {
   physical = true,
   collisionbox = { -c, -c, -c, c, c, c },
   visual = "cube",
   textures = { p, p, p, p, p, p },
   visual_size = { x = 1/res, y = 1/res },
   automatic_rotate = false,
   
   on_punch = function(self, hitter)
      local name = hitter:get_wielded_item():get_name()
      name = string.split(name, "_")[2]
      grid[self.pos.x][self.pos.y]=colors[name]

      local p = textures[name]
      if p then
         self.object:set_properties({textures = { p, p, p, p, p, p }})
      end
   end
}

brush = {                  
   description = "brush",
   inventory_image = "default_tool_steelaxe.png",
   wield_image = "",
   wield_scale = {x=1,y=1,z=1},
   stack_max = 99,
   liquids_pointable = false,
   tool_capabilities = {
      full_punch_interval = 1.0,
      max_drop_level=0,
      groupcaps={
         -- For example:
         fleshy={times={[2]=0.80, [3]=0.40}, maxwear=0.05, maxlevel=1},
         snappy={times={[2]=0.80, [3]=0.40}, maxwear=0.05, maxlevel=1},
         choppy={times={[3]=0.90}, maxwear=0.05, maxlevel=0}
      }
   }
}

minetest.register_entity("painting:picent", picent)
minetest.register_node("painting:pic", picnode) 

minetest.register_craftitem("painting:canvas", canvas)
minetest.register_craftitem("painting:paintedcanvas", paintedcanvas)
minetest.register_node("painting:canvasnode", canvasnode)

minetest.register_node("painting:easel", easel)

colors = {}
revcolors = {}

for color, _ in pairs(textures) do
   table.insert(revcolors, color)
   
   minetest.register_entity("painting:pixel_"..color, pixel)
   minetest.register_tool("painting:brush_"..color, brush)
end

for i, color in ipairs(revcolors) do
   colors[color] = i
end

minetest.register_alias('easel', 'painting:easel')
minetest.register_alias('canvas', 'painting:canvas')

function initgrid()
   grid = {}
   for x = 0, res-1 do
      grid[x] = {}
      for y = 0, res-1 do
         grid[x][y] = colors["white"]
      end
   end
end

function to_imagestring(data)
   if not data then return end
   local imagestring = "[combine:"..res.."x"..res..":"
   local i = 1
   for y = 0, res-1 do
      for x = 0, res-1 do
         imagestring  = imagestring..x..","..y.."="..revcolors[data[i]]..".png:"
         i = i + 1
      end
   end
   return imagestring
end

initgrid()
