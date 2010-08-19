
class Cell
	def initialize borders=nil, walls=nil
		@borders= ( borders.nil? ? 0 : borders )
		@walls= (walls.nil? ? 3 : walls)
		@neighbors={:north=>nil, :east=>nil, :south=>nil, :west=>nil}
	end

	def set_north_wall
		@walls+=1 unless @walls.odd?
	end

	def unset_north_wall
		@walls-=1 if @walls.odd?
	end

	def set_north_border
		@borders+=1 unless @borders.odd?
	end

	def unset_north_border
		@borders-=1 if @borders.odd?
	end

	def set_west_wall
		@walls+=2 unless @walls.even?
	end

	def unset_west_wall
		@walls-=2 if @walls.even?
	end

	def set_west_border
		@borders+=2 unless @borders.even?
	end

	def unset_west_border
		@borders-=2 if @borders.even?
	end
	
	def add_neighbor direction, neighbor
		@neighbors[direction]=neighbor
	end

	def del_neighbor direction
		@neighbors[direction]=nil
	end

	def dump
		[@borders,@walls]
	end

end
