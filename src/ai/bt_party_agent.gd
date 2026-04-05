# bt_party_agent.gd
class_name BTPartyAgent
extends PartyAgent

## Behavior-tree fallback party agent with expertise-modulated decision making.

@export var state: PartyMemberState
@export var skill_execution: SkillExecutionSystem
@export_range(0.0, 1.0) var expertise_scalar: float = 0.5
@export var decision_interval: float = 0.5

var _decision_timer: float = 0.0
var _active_tier: int = 1

func _ready() -> void:
	if not state:
		state = get_parent().get_node_or_null("PartyMemberState")
	if not skill_execution:
		skill_execution = get_parent().get_node_or_null("SkillExecutionSystem")

func on_ai_resume_control(new_context: Dictionary) -> void:
	super.on_ai_resume_control(new_context)
	if state:
		_active_tier = state.character_data.get_active_tier(state.character_level)
	_decision_timer = 0.0

func _process(delta: float) -> void:
	if not is_active or not state or not state.is_alive: return
	
	_decision_timer -= delta
	if _decision_timer <= 0.0:
		_make_decision()

func _make_decision() -> void:
	if not state or not state.is_alive: return
	
	var scores: Array[float] = [0.0, 0.0, 0.0, 0.0]
	var available: Array[int] = []
	
	for i in range(4):
		if state.can_use_skill(i):
			scores[i] = _score_skill(i)
			available.append(i)
			
	if available.is_empty():
		_decision_timer = _get_decision_delay()
		return
		
	var selected_slot: int = -1
	
	# Expertise noise
	if randf() > expertise_scalar and available.size() > 1:
		selected_slot = available[randi() % available.size()]
	else:
		# Pick highest scoring
		var best_score: float = -INF
		for i in available:
			if scores[i] > best_score:
				best_score = scores[i]
				selected_slot = i
				
	if selected_slot >= 0 and skill_execution:
		skill_execution.try_activate_skill(selected_slot, _active_tier)
		
	_decision_timer = _get_decision_delay()

func _score_skill(slot: int) -> float:
	if not state or not state.can_use_skill(slot): return 0.0
	
	var base_score: float = 1.0
	var cls := state.character_data.character_class
	
	match cls:
		CharacterData.CharacterClass.TANKER:
			if slot == 0: base_score = 3.0
			elif state.get_hp_ratio() < 0.3: base_score = 4.0
			else: base_score = 1.5
		CharacterData.CharacterClass.HEALER:
			if slot <= 1:
				base_score = 4.0 if _ally_needs_healing() else 2.0
			else:
				base_score = 1.0
		CharacterData.CharacterClass.SUPPORT:
			if slot <= 1: base_score = 3.0
			else: base_score = 1.5
		CharacterData.CharacterClass.MAGE, CharacterData.CharacterClass.ASSASSIN, CharacterData.CharacterClass.ARCHER:
			base_score = 1.0 + slot * 0.5
		CharacterData.CharacterClass.SWORDMAN:
			if slot <= 1: base_score = 2.0
			else: base_score = 2.5 if state.get_hp_ratio() < 0.5 else 1.5
			
	return base_score

func _ally_needs_healing() -> bool:
	var allies: Array = context.get("allies", [])
	for ally in allies:
		if ally and ally.has_method("is_alive") and ally.is_alive() and ally.call("get_hp_ratio") < 0.5:
			return true
	return false

func _get_decision_delay() -> float:
	var random_factor := 1.0 + (1.0 - expertise_scalar) * randf_range(0.0, 0.5)
	return decision_interval * random_factor
