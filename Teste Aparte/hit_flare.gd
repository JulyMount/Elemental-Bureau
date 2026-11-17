extends Node2D

@onready var particles: GPUParticles2D = $GPUParticles2D

func _ready() -> void:
	particles.emitting = true
	# Destrói a cena automaticamente quando o hit terminar
	particles.finished.connect(queue_free)

# Apenas para você testar na cena isolada apertando Espaço
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		particles.restart()
