extends Node

const Match = preload("res://source/match/MatchUtils.gd")


class Set:
	extends "res://source/utils/Set.gd"

	static func from_array(array):
		var a_set = Set.new()
		for item in array:
			a_set.add(item)
		return a_set

	static func subtracted(minuend, subtrahend):
		var difference = Set.new()
		for item in minuend.iterate():
			if not subtrahend.has(item):
				difference.add(item)
		return difference


class Dict:
	static func items(dict):
		var pairs = []
		for key in dict:
			pairs.append([key, dict[key]])
		return pairs


class Float:
	static func is_equal_approx_with_epsilon(a: float, b: float, epsilon):
		return abs(a - b) <= epsilon


class Colour:
	static func is_equal_approx_with_epsilon(a: Color, b: Color, epsilon: float):
		return (
			Float.is_equal_approx_with_epsilon(a.r, b.r, epsilon)
			and Float.is_equal_approx_with_epsilon(a.g, b.g, epsilon)
			and Float.is_equal_approx_with_epsilon(a.b, b.b, epsilon)
		)


class NodeEx:
	static func find_parent_with_group(node, group_for_parent_to_be_in):
		var ancestor = node.get_parent()
		while ancestor != null:
			if ancestor.is_in_group(group_for_parent_to_be_in):
				return ancestor
			ancestor = ancestor.get_parent()
		return null


class Arr:
	static func sum(array):
		var total = 0
		for item in array:
			total += item
		return total


class RouletteWheel:
	var _values_w_sorted_normalized_shares = []

	func _init(value_to_share_mapping):
		var total_share = Arr.sum(value_to_share_mapping.values())
		for value in value_to_share_mapping:
			var share = value_to_share_mapping[value]
			var normalized_share = share / total_share
			_values_w_sorted_normalized_shares.append([value, normalized_share])
		for i in range(1, _values_w_sorted_normalized_shares.size()):
			_values_w_sorted_normalized_shares[i][1] += _values_w_sorted_normalized_shares[i - 1][1]

	func get_value(probability):
		for tuple in _values_w_sorted_normalized_shares:
			var value = tuple[0]
			var accumulated_share = tuple[1]
			if probability <= accumulated_share:
				return value
		assert(false, "unexpected flow")
		return -1

class Vec3:
	static func serialize(vec: Vector3) -> String:
		var packedFloat = PackedFloat32Array([vec.x,vec.y,vec.z])
		var returnstring = Marshalls.variant_to_base64(packedFloat)
		return returnstring
		#print("serialize {0},{1},{2}".format(packedFloat.to_byte_array()))
		#return "{0},{1},{2}".format([vec.x,vec.y,vec.z])
	static func deserialize(str: String) -> Vector3:
		var packedFloat = Marshalls.base64_to_variant(str)
		return Vector3(packedFloat[0],packedFloat[1],packedFloat[2])
		#var split = str.split(",")
		#var packedFloat = PackedByteArray()
		#return Vector3(split[0].to_float(),split[1].to_float(),split[2].to_float())
