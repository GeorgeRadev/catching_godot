extends Spatial

# for 3D
onready var cameraL:Camera = $ViewportContainerL/ViewportL/CameraL
onready var cameraR:Camera = $ViewportContainerR/ViewportR/CameraR

onready var CHIP:Spatial = $CHIP
onready var CHIP_Animation:AnimationPlayer = $CHIP/AnimationPlayer
onready var DALE:Spatial = $DALE
onready var DALE_Animation:AnimationPlayer = $DALE/AnimationPlayer
onready var DONALD:Spatial = $DONALD
onready var DONALD_Animation:AnimationPlayer = $DONALD/AnimationPlayer
onready var FALLINGS:Spatial = $FALLINGS
onready var templates:Spatial = $Templates
onready var alicorn:Spatial = $Templates/alicorn
onready var popcorn:Spatial = $Templates/popcorn
onready var heart:Spatial = $Templates/heart
onready var star:Spatial = $Templates/star

onready var countCHIP:Button = $countCHIP
onready var countDALE:Button = $countDALE
onready var countDONALD:Button = $countDONALD
onready var messageText:Button = $messageText

onready var audioAlicorn:AudioStreamPlayer = $audioAlicorn
onready var audioPopcorn:AudioStreamPlayer = $audioPopcorn
onready var audioStar:AudioStreamPlayer = $audioStar
onready var audioHeart:AudioStreamPlayer = $audioHeart

const v0:Vector3 = Vector3.ZERO
const vx:Vector3 = Vector3(1,0,0)
const vz:Vector3 = Vector3(0,0,1)

var positionCHIP:Vector3 = Vector3(-2,0,0)
var directionCHIP:Vector3 = Vector3(0,0,-1)
var speedCHIP:float = 0

var positionDALE:Vector3 = Vector3(2,0,0)
var directionDALE:Vector3 = Vector3(0,0,-1)
var speedDALE:float = 0

var positionDONALD:Vector3 = Vector3(-5,0,-5)
var directionDONALD:Vector3 = Vector3(1,0,1)
var speedDONALD:float = 0

const arenaSize:float = 5.5
var fallSpeed:Vector3
var fallingObjects:Array = []
var popRate:float
var currentRate:float = 0.0

const catchCountThreshold:int = 20
var winTimeout:float = -1
var catchCountCHIP:int = 0
var catchCountDALE:int = 0
var catchCountDONALD:int = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	var _err = get_tree().get_root().connect("size_changed", self, "resize")
	randomize()
	templates.visible = false
	CHIP.visible = true
	DALE.visible = true
	DONALD.visible = true
	CHIP_Animation.play("idle")
	DALE_Animation.play("idle")
	DONALD_Animation.play("idle")
	set_process_input(true)
	resize()
	reset()
	
	
func reset():
	winTimeout = -1
	popRate = 0.5
	fallSpeed = Vector3(0,2,0)
	positionCHIP = Vector3(-2,0,0)
	positionDALE = Vector3(2,0,0)
	positionDONALD = Vector3(-5,0,-5)
	directionCHIP = Vector3(0,0,1)
	directionDALE = Vector3(0,0,1)
	directionDONALD = Vector3(1,0,1)
	catchCountCHIP = 0
	catchCountDALE = 0
	catchCountDONALD = 0
	fallingObjects.clear()
	delete_children(FALLINGS)
	updateText()
	setMessageText("START !!!", 3)

func updateText():
	countCHIP.text = "CHIP:  " + str(catchCountCHIP)
	countDALE.text = "DALE:  " + str(catchCountDALE)
	countDONALD.text = "DONALD:  " + str(catchCountDONALD)

var messageTextDissapear:float = -1
func setMessageText(s:String, seconds:float):
	messageText.text = s
	messageTextDissapear = seconds

func _input(_ev):
		#reset
	if Input.is_key_pressed(KEY_R): reset()
	# no winner yet
	if winTimeout < 0:
		#dale movements
		var vectorDALE:Vector3 = v0
		if Input.is_action_pressed("dale_left"): vectorDALE -= vx
		if Input.is_action_pressed("dale_right"): vectorDALE += vx
		if Input.is_action_pressed("dale_up"): vectorDALE -= vz
		if Input.is_action_pressed("dale_down"): vectorDALE += vz
		if vectorDALE.length() > 0.2: 
			speedDALE = 1.0
			directionDALE = 0.3 * directionDALE + 2 * vectorDALE.normalized()
			directionDALE = directionDALE.normalized()
	
		#chip movements
		var vectorCHIP:Vector3 = v0
		if Input.is_action_pressed("chip_left"): vectorCHIP -= vx
		if Input.is_action_pressed("chip_right"): vectorCHIP += vx
		if Input.is_action_pressed("chip_up"): vectorCHIP -= vz
		if Input.is_action_pressed("chip_down"): vectorCHIP += vz
		if vectorCHIP.length() > 0.2: 
			speedCHIP = 1.0
			directionCHIP = 0.3 * directionCHIP + 2 * vectorCHIP.normalized()
			directionCHIP = directionCHIP.normalized()
		
		#donald movement to the first non-taken element
		if fallingObjects.size() > 0:
			var lastObject:Spatial = fallingObjects[fallingObjects.size()-1]
			var distVector = (lastObject.translation - positionDONALD)
			distVector.y = 0
			distVector.normalized()
			directionDONALD = distVector
			speedDONALD = 1
	
		if Input.is_action_just_pressed("3d_toggle"):
			OS.window_fullscreen = not OS.window_fullscreen
			if OS.window_fullscreen:
				cameraL.translate(Vector3(-0.16,0,0))
				cameraR.translate(Vector3( 0.16,0,0))
			else:
				cameraL.translate(Vector3(0.16,0,0))
				cameraR.translate(Vector3(-0.16,0,0))
			resize()
		# drop speed
		if Input.is_key_pressed(KEY_EQUAL):
			fallSpeed += Vector3(0,0.1, 0)
		if Input.is_key_pressed(KEY_MINUS):
			if fallSpeed.y > 2:
				fallSpeed -= Vector3(0, 0.1, 0)
		# drop ratio
		if Input.is_key_pressed(KEY_2):
			popRate -= 0.1
		if Input.is_key_pressed(KEY_1):
			if popRate < 3: popRate += 0.1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	hideMessageText(delta)
	# we hav a winner
	if winTimeout > 0:
		winTimeout -= delta
		if winTimeout < 0: reset()
		if catchCountCHIP + catchCountDALE >= catchCountThreshold:
			CHIP_Animation.play("win")
			DALE_Animation.play("win")
			DONALD_Animation.play("lose")
		else:
			CHIP_Animation.play("lose")
			DALE_Animation.play("lose")
			DONALD_Animation.play("win")
	else:
		# normal game cycle
		movementAndInertial(delta)
		generateObjects(delta)
		scrollObjects(delta)
		checkColisions()

func movementAndInertial(delta):
	#DALE
	var newPositionDALE = positionDALE + delta * 4 * speedDALE * directionDALE
	if abs(newPositionDALE.x) < arenaSize and abs(newPositionDALE.z) < arenaSize:
		positionDALE = newPositionDALE
	DALE.transform = Transform.IDENTITY
	DALE.translate(positionDALE)
	DALE.rotate_y(atan2(-directionDALE.z, directionDALE.x))
	if speedDALE > 0.2:
		speedDALE -= 2 * delta
		DALE_Animation.play("run")
	else:
		speedDALE = 0
		DALE_Animation.play("idle")
	#CHIP
	var newPositionCHIP = positionCHIP + delta * 4 * speedCHIP * directionCHIP
	if abs(newPositionCHIP.x) < arenaSize and abs(newPositionCHIP.z) < arenaSize:
		positionCHIP = newPositionCHIP
	CHIP.transform = Transform.IDENTITY
	CHIP.translate(positionCHIP)
	CHIP.rotate_y(atan2(-directionCHIP.z, directionCHIP.x))
	if speedCHIP > 0.2: 
		speedCHIP -= 2 * delta
		CHIP_Animation.play("run")
	else:
		speedCHIP = 0
		CHIP_Animation.play("idle")
	#DONALD
	directionDONALD = directionDONALD.normalized()
	var newPositionDONALD = positionDONALD + delta * speedDONALD * directionDONALD
	if abs(newPositionDONALD.x) < arenaSize and abs(newPositionDONALD.z) < arenaSize:
		positionDONALD = newPositionDONALD
	DONALD.transform = Transform.IDENTITY
	DONALD.translate(positionDONALD)
	DONALD.rotate_y(atan2(-directionDONALD.z, directionDONALD.x))
	if speedDONALD > 0.2: 
		speedDONALD -= 2 * delta
		DONALD_Animation.play("run")
	else:
		speedDONALD = 0
		DONALD_Animation.play("idle")

func hideMessageText(delta):
	if messageTextDissapear > 0:
		messageTextDissapear -= delta
		var rem = fmod(3 * messageTextDissapear,1)
		var color = Color(1, rem, rem)
		messageText.add_color_override("font_color", color)
		if messageTextDissapear < 0:
			messageText.text = ""

func sort_nan(a, b):
	return (a < b or b != b)

func checkColisions():
	# check bone
	for ix in range(fallingObjects.size()-1, -1, -1):
		var chipWin = hasColision(positionCHIP, fallingObjects[ix].translation) 
		var daleWin = hasColision(positionDALE, fallingObjects[ix].translation)
		var donaldWin = hasColision(positionDONALD, fallingObjects[ix].translation)

		if chipWin == chipWin or daleWin == daleWin or donaldWin == donaldWin:
			FALLINGS.remove_child(fallingObjects[ix])
			fallingObjects.remove(ix)
			# play coin 
			audioAlicorn.play()
			# sort dostances
			var distances: Array = [chipWin, daleWin, donaldWin]
			distances.sort_custom(self, "sort_nan")
			var win:float = distances[0]
			if win == win:
				# using that NaN is false for all operations, except NaN != NaN
				if chipWin == win: 
					catchCountCHIP += 1
				elif daleWin == win: 
					catchCountDALE += 1
				elif donaldWin == win: 
					catchCountDONALD += 1
				updateText()
				# we have winner
				if catchCountCHIP + catchCountDALE>= catchCountThreshold:
					winTimeout = 6
					setMessageText("CHIP & DALE are WINNERS !!!", winTimeout)
				elif catchCountDONALD >= catchCountThreshold:
					winTimeout = 6
					setMessageText("DONALD is a WINNER !!!", winTimeout)
				# face the camera on winning/loosing
				if winTimeout > 0:
					CHIP.transform = Transform.IDENTITY
					CHIP.translate(positionCHIP)
					CHIP.rotate_y(PI*3/2)
					DALE.transform = Transform.IDENTITY
					DALE.translate(positionDALE)
					DALE.rotate_y(PI*3/2)
					DONALD.transform = Transform.IDENTITY
					DONALD.translate(positionDONALD)
					DONALD.rotate_y(PI*3/2)

func generateObjects(delta):
	var obj = null
	currentRate += delta
	if currentRate > popRate:
		currentRate = 0
		var chance:float = 4 * randf()
		if chance > 3: obj = alicorn.duplicate()
		elif chance > 2: obj = popcorn.duplicate()
		elif chance > 1: obj = star.duplicate()
		else: obj = heart.duplicate()
		obj.rotate_y(randf()*PI)
		fallingObjects.push_front(obj)
	
	if obj != null:
		var angle:float = 2*PI*randf()
		var length:float = arenaSize * randf()
		obj.translation = Vector3(length*cos(angle),10, length*sin(angle))
		obj.visible = true
		FALLINGS.add_child(obj)

func scrollObjects(delta):
	# scroll objects
	var scroll:Vector3 = - delta * fallSpeed
	for obj in fallingObjects:
		obj.translation += scroll
		if obj.translation.y <= 1: obj.translation.y = 1

func hasColision(position:Vector3, obj: Vector3):
	if (obj.y - 1 < 1 ):
		var absDist:float = position.distance_squared_to(obj)
		if absDist < 1.2: return absDist
	return NAN

func resize():
	var viewport = get_tree().get_root()
	var height = viewport.get_visible_rect().size.y
	var width = viewport.get_visible_rect().size.x
	var mid = int(width/2)
	
	var D3D:bool = OS.window_fullscreen
	if D3D:
		$ViewportContainerL.margin_left = 0
		$ViewportContainerL.margin_top = 0
		$ViewportContainerL.margin_bottom = int(height/2)
		$ViewportContainerL.margin_right = int(width/2)
		$ViewportContainerL.rect_scale = Vector2(1, 2)
		$ViewportContainerL/ViewportL.set_size_override(true, Vector2(width, height))
		$ViewportContainerR.margin_left = mid
		$ViewportContainerR.margin_top = 0
		$ViewportContainerR.margin_bottom = int(height/2)
		$ViewportContainerR.margin_right = width
		$ViewportContainerR.rect_scale = Vector2(1, 2)
		$ViewportContainerR/ViewportR.set_size_override(true, Vector2(width, height))
	else:
		$ViewportContainerL.margin_left = 0
		$ViewportContainerL.margin_top = 0
		$ViewportContainerL.margin_bottom = height
		$ViewportContainerL.margin_right = width
		$ViewportContainerL.rect_scale = Vector2(1.0, 1.0)
		$ViewportContainerL/ViewportL.set_size_override(true, Vector2(width, height) )
		$ViewportContainerR.margin_left = 0
		$ViewportContainerR.margin_top = 0
		$ViewportContainerR.margin_bottom = 0
		$ViewportContainerR.margin_right = 0
		$ViewportContainerR/ViewportR.set_size_override(true, Vector2(width, height) )

func apply_material_color(mesh_instance_node:MeshInstance,  color:int):
	var material = SpatialMaterial.new()
	material.albedo_color = Color(color)
	mesh_instance_node.set_material_override(material)

func delete_children(node):
	for n in node.get_children():
		node.remove_child(n)
