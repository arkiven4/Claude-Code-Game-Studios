# simulate_rewards.gd
# Run with: godot --headless -s tools/simulate_rewards.gd
extends SceneTree

# current state simulation
var w_damage_dealt = 0.001
var w_damage_received = 0.005 # Updated
var w_skill_hit = 0.005
var w_flawless = 0.2          # Updated
var flawless_window = 120
var retreat_window = 60
var retreat_reward = 0.001

func _init():
	print("--- Reward Simulation: Hit and Run (UPDATED) ---")
	
	simulate_scenario("Face-tank (Stay in range, take damage)", 1, true)
	simulate_scenario("Hit and Run (Hit once, retreat)", 1, false)
	simulate_scenario("Trading (Hit 5 times, take 2 hits)", 5, true)
	
	quit()

func simulate_scenario(label: String, hits: int, take_damage: bool):
	print("\nScenario: %s" % label)
	
	var r = 0.0
	var damage_per_hit = 20
	var damage_taken_per_step = 2 if take_damage else 0
	var total_steps = 300
	
	var last_hit_step = -1
	var took_damage_since_hit = false
	
	print("Step | Event           | Reward")
	print("-----|-----------------|------------")
	
	for step in range(total_steps):
		var event = ""
		
		# Hit logic
		if step == 10:
			for i in range(hits):
				r += damage_per_hit * w_damage_dealt
				r += w_skill_hit * 2.0
			event = "Hit x%d" % hits
			last_hit_step = step
			took_damage_since_hit = false
		
		# Taking damage
		if take_damage and step >= 10 and step < 100:
			r -= damage_taken_per_step * w_damage_received
			took_damage_since_hit = true
			if step % 30 == 0:
				event = "Taking Dmg"
		
		# Retreat reward (simulated as "being safe" for retreat_window steps after hit)
		if last_hit_step > 0 and step < last_hit_step + retreat_window:
			if not took_damage_since_hit:
				r += retreat_reward
				if step == last_hit_step + 30:
					event = "Retreating"
		
		# Flawless check
		if last_hit_step > 0 and step == last_hit_step + flawless_window:
			if not took_damage_since_hit:
				r += w_flawless
				event = "Flawless!"
		
		if event != "":
			print("%4d | %-15s | %10.4f" % [step, event, r])
	
	print("Final|                 | %10.4f" % r)
