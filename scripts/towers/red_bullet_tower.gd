extends StaticBody2D

var RedBullet =preload("res://scenes/bullets/RedBullet.tscn")
var bulletDammage = 5
var pathName
var currTargets = []
var curr
var team = ""
var reload = 0
var range = 400
var health = 10

@onready var timer = get_node("Upgrade/ProgressBar/Timer")
var startShooting = false

#var sprite 
#
#func _ready():
	#var sprite = get_node("TowerDefenseTile250")
func _process(delta):
	#get_node("Upgrade/ProgressBar").global_position = self.position + Vector2(-64,-81)
	get_node("Upgrade/ProgressBar").z_index=900
	if is_instance_valid(curr):
		#print("curr ok")
		self.look_at(curr.global_position)
		#if timer.is_stopped():
			#print("timer start")
			#timer.start()
	else:
		for i in get_node("BulletContainer").get_child_count():
			get_node("BulletContainer").get_child(i).queue_free()
	#update_powers()


func Shoot():
	var tempBullet = RedBullet.instantiate()
	tempBullet.set_target(curr)
	tempBullet.pathName = pathName
	tempBullet.bulletDamage = bulletDammage
	tempBullet.team = self.team
	get_node("BulletContainer").add_child(tempBullet)
	tempBullet.global_position = $Aim.global_position

#
#func _on_tower_body_entered(body):
	#if "Soldier_A" in body.name:
		#var tempArray = []
		#currTargets = get_node("Tower").get_overlapping_bodies()
		##print(currTargets)
		#for i in currTargets :
			#if "Soldier_A" in i.name :
				#tempArray.append(i)
		#var currTargets = null
		#
		#for i in tempArray : 
			#if currTargets == null : 
				#currTargets = i.get_node("../")
			#else:
				#if i.get_parent().get_progress() > currTargets.get_progress():
					#currTargets = i.get_node("../")
		#
		#curr = currTargets
		#pathName = currTargets.get_parent().name
		#
#
#
#
#func _on_tower_body_exited(body):
	#currTargets = get_node("Tower").get_overlapping_bodies()


func _on_timer_timeout():
	Shoot()


#func _on_input_event(viewport, event, shape_idx):
	#if event is InputEventMouseButton and event.button_mask == 1 and event.get_button_index()==1:
		#var towerPath = get_tree().get_root().get_node("main/Towers")
		#for i in towerPath.get_child_count():
			#if towerPath.get_child(i).name != self.name:
				#towerPath.get_child(i).get_node("Upgrade/UpgradePanel").hide()
		#get_node("Upgrade/UpgradePanel").visible = !get_node("Upgrade/UpgradePanel").visible
		#get_node("Upgrade/UpgradePanel").global_position = self.position + Vector2(-576,81)
		#
		


#func _on_range_pressed():
	#range += 30
#
#
#func _on_attack_speed_pressed():
	#if reload <= 2 :
		#reload += 0.2
	#if timer.wait_time > 0.3:
		#timer.wait_time = 3 - reload
	#
#
#
#func _on_power_pressed():
	#bulletDammage += 1
	
#func update_powers():
	#get_node("Upgrade/UpgradePanel/HBoxContainer/Range/Label").text = str(range)
	#get_node("Upgrade/UpgradePanel/HBoxContainer/AttackSpeed/Label").text = str(3 -reload)
	#get_node("Upgrade/UpgradePanel/HBoxContainer/Power/Label").text = str(bulletDammage)
	#get_node("Tower/CollisionShape2D2").shape.radius = range
	#


#func _on_range_mouse_entered():
	#get_node("Tower/CollisionShape2D2").show()
#
#
#func _on_range_mouse_exited():
	#get_node("Tower/CollisionShape2D2").hide()


func _on_tower_area_entered(area):
	
	#currTargets = get_node("Tower").get_overlapping_areas()
	var array_of_tiles = get_tree().get_nodes_in_group ( "tile" )
	var array_of_ennemi = get_tree().get_nodes_in_group ( "ennemi" )
	var array_of_player = get_tree().get_nodes_in_group ( "player" )
	#area.currTargets)
	
	if area in array_of_tiles and area in array_of_ennemi:
		print("test")
		var tempArray = []
		currTargets = get_node("Tower").get_overlapping_areas()
		print(currTargets.size())
		#print(currTargets)
		for i in currTargets :
			if  i in array_of_tiles and i in array_of_ennemi:
				print("find ennemi")
				tempArray.append(i)
		currTargets = null
		var dist=100000
		var temp_dist = 100000
		for i in tempArray: 
			temp_dist = area.global_position.distance_to(i.global_position)
			if  temp_dist < dist:
				dist = temp_dist
				currTargets = i 

			#else:
				#if i.get_parent().get_progress() > currTargets.get_progress():
					#currTargets = i.get_node("../")
		
		curr = currTargets
		pathName = currTargets.name
		Shoot()
		


func _on_tower_area_exited(area):
	currTargets = get_node("Tower").get_overlapping_areas()
