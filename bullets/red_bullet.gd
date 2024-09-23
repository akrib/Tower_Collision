extends CharacterBody2D

var target
var speed = 2000
var pathName = ""
var bulletDamage = 1
var team = ""
#var velocity 

func _physics_process(delta):
	#var pathSpawnerNode = get_tree().get_root().get_node("main/PathSpawner")
	if is_instance_valid(target):
		velocity = global_position.direction_to(target.global_position) * speed
		look_at(target.global_position)
		move_and_slide()
	
func set_target(obj):
	target = obj

func _on_area_2d_body_entered(body):
	if "tower" in body.name : 
		body.health -= bulletDamage
		queue_free()


func _on_area_2d_area_entered(area):
	var array_of_tiles = get_tree().get_nodes_in_group ( "tile" )
	var array_of_ennemi = get_tree().get_nodes_in_group ( "ennemi" )
	var array_of_player = get_tree().get_nodes_in_group ( "player" )
	if self.team == "player" and area in array_of_tiles and area in array_of_ennemi : 
		area.health -= bulletDamage
		queue_free()
	if self.team == "ennemi" and area in array_of_tiles and area in array_of_player : 
		area.health -= bulletDamage
		queue_free()
