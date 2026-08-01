class_name ScoreFormatter
extends RefCounted

## Presentation-only score formatting. The controller keeps the exact integer;
## UI layers call this helper only when the displayed value changes.
static func format(value: int) -> String:
	var magnitude := absi(value)
	if magnitude < 10000:
		return _with_grouping(value)
	var units := ["K", "M", "B", "T", "Q", "Qi"]
	var thresholds := [1000.0, 1000000.0, 1000000000.0, 1000000000000.0, 1000000000000000.0, 1000000000000000000.0]
	var unit_index := 0
	for index in range(thresholds.size()):
		if float(magnitude) >= thresholds[index]:
			unit_index = index
	var scaled: float = float(value) / float(thresholds[unit_index])
	var rounded: float = snappedf(scaled, 0.1)
	if absf(rounded) >= 1000.0 and unit_index < units.size() - 1:
		unit_index += 1
		scaled = float(value) / float(thresholds[unit_index])
		rounded = snappedf(scaled, 0.1)
	var number := "%.1f" % rounded
	if number.ends_with(".0"):
		number = number.trim_suffix(".0")
	return number + units[unit_index]

static func _with_grouping(value: int) -> String:
	var negative := value < 0
	var digits := str(absi(value))
	var grouped := ""
	for index in range(digits.length()):
		if index > 0 and (digits.length() - index) % 3 == 0:
			grouped += ","
		grouped += digits[index]
	return ("-" if negative else "") + grouped
