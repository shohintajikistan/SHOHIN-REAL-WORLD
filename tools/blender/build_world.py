import bpy, math, random, os
from mathutils import Vector
random.seed(73)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
def mat(n,c):
 m=bpy.data.materials.new(n); m.diffuse_color=(*c,1); m.use_nodes=True; m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value=(*c,1); m.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value=.9; return m
bark=mat("Bark",(.19,.085,.035)); bark2=mat("Bark highlights",(.3,.16,.08)); pine=mat("Pine needles",(.035,.16,.075)); pine2=mat("Pine sunlit",(.07,.25,.105)); leaf=mat("Broadleaf",(.055,.22,.09)); leaf2=mat("Broadleaf highlights",(.11,.31,.12)); stone=mat("Weathered stone",(.28,.32,.30)); fernmat=mat("Fern green",(.09,.29,.11))
def cone(n,r1,r2,d,z,m,v=12):
 bpy.ops.mesh.primitive_cone_add(vertices=v,radius1=r1,radius2=r2,depth=d,location=(0,0,z)); o=bpy.context.object; o.name=n; o.data.materials.append(m); return o
def ico(n,loc,sc,m):
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=1,location=loc); o=bpy.context.object; o.name=n; o.scale=sc; o.data.materials.append(m)
 for vert in o.data.vertices: vert.co*=random.uniform(.9,1.1)
 return o
def join(n,objs):
 bpy.ops.object.select_all(action='DESELECT')
 for o in objs:o.select_set(True)
 bpy.context.view_layer.objects.active=objs[0]; bpy.ops.object.join(); objs[0].name=n
 bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY',center='BOUNDS'); objs[0].location=(0,0,0); return objs[0]
objs=[cone("Pine trunk",.25,.14,4.8,2.4,bark)]
for i in range(5): objs.append(cone("Pine tier",1.55-i*.2,.02,1.7,1.25+i*.67,pine if i%2==0 else pine2,11))
join("Tree_Pine",objs)
objs=[cone("Oak trunk",.3,.18,3.8,1.9,bark)]
for i in range(14):
 a=random.random()*math.tau; r=random.uniform(.2,1.15)
 objs.append(ico("Oak canopy",(math.cos(a)*r,math.sin(a)*r,3.35+random.uniform(-.2,.8)),(.65,.58,.7),leaf if i%3 else leaf2))
join("Tree_Broadleaf",objs)
objs=[cone("Sapling trunk",.11,.06,2.4,1.2,bark)]
for i in range(5):
 a=i*math.tau/5; objs.append(ico("Sapling leaves",(math.cos(a)*.25,math.sin(a)*.25,1.9+random.random()*.5),(.4,.38,.5),leaf2))
join("Tree_Sapling",objs)
objs=[ico("Stone core",(0,0,.5),(1,.8,.65),stone)]
for i in range(5):objs.append(ico("Stone facets",(random.uniform(-.5,.5),random.uniform(-.4,.4),random.uniform(.2,.7)),(.3,.28,.22),stone))
join("Rock_Large",objs)
join("Stump",[cone("Stump",.38,.32,.72,.36,bark2)])
o=cone("Fallen log",.22,.2,2.5,.23,bark,12);o.rotation_euler[1]=math.pi/2;join("Fallen_Log",[o])
objs=[]
for i in range(7):
 a=i*math.tau/7; curve=bpy.data.curves.new("Fern stem","CURVE");curve.dimensions='3D';curve.bevel_depth=.018;sp=curve.splines.new('BEZIER');sp.bezier_points.add(2)
 for p,co in zip(sp.bezier_points,[(0,0,.08),(math.cos(a)*.4,math.sin(a)*.4,.32),(math.cos(a)*.9,math.sin(a)*.9,.65)]):p.co=co;p.handle_left_type='AUTO';p.handle_right_type='AUTO'
 ob=bpy.data.objects.new("Fern frond",curve);bpy.context.collection.objects.link(ob);ob.data.materials.append(fernmat);objs.append(ob)
join("Fern_Cluster",objs)
out=os.path.join(os.getcwd(),"assets","generated");os.makedirs(out,exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=os.path.join(out,"forest_pack.glb"),export_format='GLB',use_selection=True,export_apply=True)
print("SHOHIN forest pack exported")
