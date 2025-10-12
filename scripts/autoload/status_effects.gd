extends Node
class_name StatusEffects

# Cette classe doit être ajoutée comme enfant des entités qui peuvent recevoir des effets
# Exemple : Tuiles, Tours

# Effets actifs
var active_effects = {}

# Types d'effets
enum EffectType { POISON, BURN, SLOW, STUN, BUFF_DAMAGE, BUFF_SPEED, SHIELD }

# Référence au parent
var parent_entity

func _ready():
	parent_entity = get_parent()

func _process(delta):
	# Traiter tous les effets actifs
	for effect_name in active_effects.keys():
		var effect = active_effects[effect_name]
		effect.time_remaining -= delta
		
		# Appliquer l'effet selon son type
		match effect.type:
			EffectType.POISON, EffectType.BURN:
				apply_damage_over_time(effect, delta)
			EffectType.SLOW:
				apply_slow_effect(effect)
			EffectType.STUN:
				apply_stun_effect(effect)
			EffectType.BUFF_DAMAGE:
				apply_damage_buff_effect(effect)
			EffectType.BUFF_SPEED:
				apply_speed_buff_effect(effect)
			EffectType.SHIELD:
				apply_shield_effect(effect)
		
		# Retirer l'effet s'il est expiré
		if effect.time_remaining <= 0:
			remove_effect(effect_name)

# ============================================================================
# AJOUTER DES EFFETS
# ============================================================================

func apply_poison(damage_per_second: int, duration: float):
	"""Applique un effet de poison"""
	var effect = {
		"type": EffectType.POISON,
		"damage_per_second": damage_per_second,
		"duration": duration,
		"time_remaining": duration,
		"tick_timer": 0.0
	}
	active_effects["poison"] = effect

func apply_burn(damage_per_second: int, duration: float):
	"""Applique un effet de brûlure"""
	var effect = {
		"type": EffectType.BURN,
		"damage_per_second": damage_per_second,
		"duration": duration,
		"time_remaining": duration,
		"tick_timer": 0.0
	}
	active_effects["burn"] = effect

func apply_slow(slow_multiplier: float, duration: float):
	"""Applique un effet de ralentissement"""
	var effect = {
		"type": EffectType.SLOW,
		"multiplier": slow_multiplier,
		"duration": duration,
		"time_remaining": duration
	}
	active_effects["slow"] = effect

func apply_stun(duration: float):
	"""Applique un effet d'étourdissement"""
	var effect = {
		"type": EffectType.STUN,
		"duration": duration,
		"time_remaining": duration
	}
	active_effects["stun"] = effect

func apply_damage_buff(damage_multiplier: float, duration: float):
	"""Applique un buff de dégâts"""
	var effect = {
		"type": EffectType.BUFF_DAMAGE,
		"multiplier": damage_multiplier,
		"duration": duration,
		"time_remaining": duration
	}
	active_effects["damage_buff"] = effect

func apply_speed_buff(speed_multiplier: float, duration: float):
	"""Applique un buff de vitesse"""
	var effect = {
		"type": EffectType.BUFF_SPEED,
		"multiplier": speed_multiplier,
		"duration": duration,
		"time_remaining": duration
	}
	active_effects["speed_buff"] = effect

func apply_shield(shield_amount: int, duration: float):
	"""Applique un bouclier"""
	var effect = {
		"type": EffectType.SHIELD,
		"amount": shield_amount,
		"duration": duration,
		"time_remaining": duration
	}
	active_effects["shield"] = effect

# ============================================================================
# APPLIQUER LES EFFETS
# ============================================================================

func apply_damage_over_time(effect: Dictionary, delta: float):
	"""Applique des dégâts sur la durée"""
	effect.tick_timer += delta
	
	# Appliquer les dégâts chaque seconde
	if effect.tick_timer >= 1.0:
		effect.tick_timer -= 1.0
		
		if parent_entity.has_method("take_damage"):
			parent_entity.take_damage(effect.damage_per_second)
		elif parent_entity.has("health"):
			parent_entity.health -= effect.damage_per_second

func apply_slow_effect(effect: Dictionary):
	"""Applique l'effet de ralentissement"""
	# Cette méthode doit être appelée par l'entité pour obtenir le multiplicateur de vitesse
	pass

func apply_stun_effect(effect: Dictionary):
	"""Applique l'effet d'étourdissement"""
	# Empêcher l'entité d'agir
	if parent_entity.has("is_stunned"):
		parent_entity.is_stunned = true

func apply_damage_buff_effect(effect: Dictionary):
	"""Applique le buff de dégâts"""
	# Le buff est appliqué via get_damage_multiplier()
	pass

func apply_speed_buff_effect(effect: Dictionary):
	"""Applique le buff de vitesse"""
	# Le buff est appliqué via get_speed_multiplier()
	pass

func apply_shield_effect(effect: Dictionary):
	"""Applique le bouclier"""
	# Le bouclier absorbe les dégâts via absorb_damage()
	pass

# ============================================================================
# GETTERS POUR LES MULTIPLICATEURS
# ============================================================================

func get_speed_multiplier() -> float:
	"""Retourne le multiplicateur de vitesse total"""
	var multiplier = 1.0
	
	# Ralentissement
	if active_effects.has("slow"):
		multiplier *= active_effects.slow.multiplier
	
	# Buff de vitesse
	if active_effects.has("speed_buff"):
		multiplier *= active_effects.speed_buff.multiplier
	
	# Stun = vitesse 0
	if active_effects.has("stun"):
		return 0.0
	
	return multiplier

func get_damage_multiplier() -> float:
	"""Retourne le multiplicateur de dégâts total"""
	var multiplier = 1.0
	
	if active_effects.has("damage_buff"):
		multiplier *= active_effects.damage_buff.multiplier
	
	return multiplier

func absorb_damage(damage: int) -> int:
	"""Absorbe les dégâts avec le bouclier, retourne les dégâts restants"""
	if not active_effects.has("shield"):
		return damage
	
	var shield = active_effects.shield
	var absorbed = min(damage, shield.amount)
	shield.amount -= absorbed
	
	# Retirer le bouclier s'il est épuisé
	if shield.amount <= 0:
		remove_effect("shield")
	
	return damage - absorbed

# ============================================================================
# GESTION DES EFFETS
# ============================================================================

func remove_effect(effect_name: String):
	"""Retire un effet"""
	if active_effects.has(effect_name):
		# Nettoyage spécifique selon le type
		match active_effects[effect_name].type:
			EffectType.STUN:
				if parent_entity.has("is_stunned"):
					parent_entity.is_stunned = false
		
		active_effects.erase(effect_name)

func clear_all_effects():
	"""Retire tous les effets"""
	for effect_name in active_effects.keys():
		remove_effect(effect_name)

func has_effect(effect_name: String) -> bool:
	"""Vérifie si un effet est actif"""
	return active_effects.has(effect_name)

func get_effect(effect_name: String) -> Dictionary:
	"""Retourne un effet actif"""
	return active_effects.get(effect_name, {})

# ============================================================================
# UTILITAIRES
# ============================================================================

func get_active_effects_count() -> int:
	"""Retourne le nombre d'effets actifs"""
	return active_effects.size()

func is_crowd_controlled() -> bool:
	"""Vérifie si l'entité est sous contrôle de foule"""
	return has_effect("stun") or has_effect("slow")

func is_buffed() -> bool:
	"""Vérifie si l'entité a des buffs"""
	return has_effect("damage_buff") or has_effect("speed_buff") or has_effect("shield")

func is_debuffed() -> bool:
	"""Vérifie si l'entité a des debuffs"""
	return has_effect("poison") or has_effect("burn") or has_effect("slow") or has_effect("stun")
