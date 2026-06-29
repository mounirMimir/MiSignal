--!strict
-- obtained from typeforge
type function table_flatten_with(
	input: typeof(types.newtable()),
	with: typeof(types.newtable()),
	can_add_read_indexer: boolean,
	can_add_write_indexer: boolean
)
	for key, value in with:properties() do
		local can_add_read_property = not input:readproperty(key)
		local can_add_write_property = not input:writeproperty(key)

		if can_add_read_property and can_add_write_property then
			local value_read, value_write = value.read, value.write

			if value_read == value_write then
				input:setproperty(key, value_read)
			else
				if value_read then
					input:setreadproperty(key, value_read)
				end

				if value_write then
					input:setwriteproperty(key, value_write)
				end
			end
		else
			if can_add_read_property then
				local value_read = value.read
				if value_read then
					input:setreadproperty(key, value_read)
				end
			end

			if can_add_write_property then
				local value_write = value.write
				if value_write then
					input:setwriteproperty(key, value_write)
				end
			end
		end
	end

	local indexer = with:indexer()
	if indexer then
		if can_add_read_indexer and can_add_write_indexer then
			local indexer_read, indexer_write = indexer.readresult, indexer.writeresult

			if indexer_read == indexer_write then
				input:setindexer(indexer.index, indexer_read)
			else
				if indexer_read and indexer_write then
					local indexer_index = indexer.index
					input:setreadindexer(indexer_index, indexer_read)
					input:setwriteindexer(indexer_index, indexer_write)
					can_add_read_indexer, can_add_write_indexer = false, false
				elseif indexer_read then
					input:setreadindexer(indexer.index, indexer_read)
					can_add_read_indexer = false
				elseif indexer_write then
					input:setwriteindexer(indexer.index, indexer_write)
					can_add_write_indexer = false
				end
			end
		else
			if can_add_read_indexer then
				local indexer_read = indexer.readresult
				if indexer_read then
					input:setreadindexer(indexer.index, indexer_read)
					can_add_read_indexer = false
				end
			elseif can_add_write_indexer then
				local indexer_write = indexer.writeresult
				if indexer_write then
					input:setwriteindexer(indexer.index, indexer_write)
					can_add_write_indexer = false
				end
			end
		end
	end

	return can_add_read_indexer, can_add_write_indexer
end

type function components_map(input: { type }, callback: (value: type, ...type) -> type, ...: type)
	for idx, value in input do
		input[idx] = callback(value, ...)
	end
	return input
end

type function intersection_from_components(input: { type })
	local input_len = #input
	return if input_len == 0 then nil elseif input_len == 1 then input[1] else types.intersectionof(table.unpack(input))
end

export type function FlattenTable(input: type)
	local input_tag = input.tag
	if input_tag == "table" then
		return input
	end
	if input_tag ~= "intersection" then
		return input
	end

	local components = components_map(input:components(), FlattenTable)

	local output: typeof(types.newtable()), output_idx: number
	local can_add_read_indexer, can_add_write_indexer

	local output_non_table_intersection_components: { type } = {}

	for idx, component in components do
		local component_tag = component.tag

		if component_tag == "intersection" then
			local sub_components = FlattenTable(component):components()
			local sub_output_idx

			for sub_idx, sub_component in sub_components do
				if sub_component.tag == "table" then
					output = sub_component
					can_add_read_indexer = not output:readindexer()
					can_add_write_indexer = not output:writeindexer()

					sub_output_idx = sub_idx
					output_idx = idx
					break
				end

				table.insert(output_non_table_intersection_components, sub_component)
			end

			if sub_output_idx then
				for sub_idx = sub_output_idx + 1, #sub_components do
					local sub_component = sub_components[sub_idx]

					if sub_component.tag == "table" then
						can_add_read_indexer, can_add_write_indexer =
							table_flatten_with(output, sub_component, can_add_read_indexer, can_add_write_indexer)
					else
						table.insert(output_non_table_intersection_components, sub_component)
					end
				end

				break
			end
		elseif component_tag == "table" then
			output = component
			can_add_read_indexer = not output:readindexer()
			can_add_write_indexer = not output:writeindexer()

			output_idx = idx
			break
		else
			table.insert(output_non_table_intersection_components, component)
		end
	end

	if not output then
		return intersection_from_components(components)
	end

	local components_len = #components
	for idx = components_len, output_idx + 1, -1 do
		local component = components[idx]
		local component_tag = component.tag

		if component_tag == "intersection" then
			for _, sub_component in FlattenTable(component):components() do
				if sub_component.tag == "table" then
					can_add_read_indexer, can_add_write_indexer =
						table_flatten_with(output, sub_component, can_add_read_indexer, can_add_write_indexer)
				else
					table.insert(output_non_table_intersection_components, sub_component)
				end
			end
		elseif component_tag == "table" then
			can_add_read_indexer, can_add_write_indexer =
				table_flatten_with(output, component, can_add_read_indexer, can_add_write_indexer)
		else
			table.insert(output_non_table_intersection_components, component)
		end
	end

	if #output_non_table_intersection_components ~= 0 then
		table.insert(output_non_table_intersection_components, output)

		output = intersection_from_components(output_non_table_intersection_components)
	end

	return output
end

export type function ReadWrite(input: typeof(types.newtable()))
	if input.tag ~= "table" then
		return types.never
	end

	for key, value in input:properties() do
		local value_read, value_write = value.read, value.write

		if value_read and not value_write then
			input:setproperty(key, value_read)
		elseif value_write and not value_read then
			input:setproperty(key, value_write)
		end
	end

	return input
end

return nil
