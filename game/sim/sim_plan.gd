class_name SimPlan
extends RefCounted

const JOB_REST: String = "REST"
const JOB_REPAIR: String = "REPAIR"
const JOB_CLEAN: String = "CLEAN"
const JOB_FARM: String = "FARM"
const JOB_REGOLITH: String = "REGOLITH"
const JOB_SCIENCE: String = "SCIENCE"

const VALID_JOBS: Array[String] = [
	JOB_REST,
	JOB_REPAIR,
	JOB_CLEAN,
	JOB_FARM,
	JOB_REGOLITH,
	JOB_SCIENCE
]

const OUTSIDE_JOBS: Array[String] = [
	JOB_REGOLITH,
	JOB_SCIENCE,
	JOB_CLEAN,
	"REPAIR_PANEL"
]

var jobs: Array[String] = []
var greenhouse_lights_on: bool = false
var science_gear_on: bool = false

func _init(
	p_jobs: Array = [],
	p_greenhouse_lights_on: bool = false,
	p_science_gear_on: bool = false
) -> void:
	greenhouse_lights_on = p_greenhouse_lights_on
	science_gear_on = p_science_gear_on
	if not p_jobs.is_empty():
		jobs.clear()
		for j in p_jobs:
			jobs.append(str(j))
	else:
		jobs = [JOB_REST, JOB_REST, JOB_REST, JOB_REST]

func set_job(index: int, job: String) -> void:
	if index >= 0 and index < jobs.size():
		jobs[index] = job

func get_job(index: int) -> String:
	if index >= 0 and index < jobs.size():
		return jobs[index]
	return JOB_REST

func has_outside_jobs(recycler_broken: bool = false) -> bool:
	for j in jobs:
		if OUTSIDE_JOBS.has(j):
			return true
		if j == JOB_REPAIR and not recycler_broken:
			return true
	return false

func clone() -> RefCounted:
	var copy_jobs: Array[String] = []
	for j in jobs:
		copy_jobs.append(j)
	var script: GDScript = get_script()
	return script.new(copy_jobs, greenhouse_lights_on, science_gear_on)
