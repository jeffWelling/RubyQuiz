class Cell
	def initialize borders=nil, walls=nil
		@borders= ( borders.nil? ? 0 : borders )
		@walls= (walls.nil? ? 3 : walls)
		@neighbors={:north=>nil, :east=>nil, :south=>nil, :west=>nil}
	end

	attr_accessor :neighbors

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

class Maze
	def initialize length, width
		raise "length and width must be fixnums" unless length.class==Fixnum and width.class==Fixnum
		#to compensate for starting from zero
		length-=1
		width-=1

		first_cell=nil
		@board=[[]]
		(0..length).each {|l|
			@board[l] ||=[]
			(0..width).each{|w|
				@board[l][w]||=nil
				@board[l][w]=cell=Cell.new
				next if l==0 and w==0
				if l==0
					#don't link to the one above, it doesn't exist
					@board[l][w-1].add_neighbor :east, cell
				elsif w==0
					@board[l-1][w].add_neighbor :south, cell
				else
					@board[l-1][w].add_neighbor :south, cell
					@board[l][w-1].add_neighbor :east, cell
				end
			}
		}
		@board
	end
end
