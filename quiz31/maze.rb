class Cell
  
	def initialize walls=nil
		@walls= {}
		@neighbors= {}
	end

	attr_accessor :neighbors

	def set_north_wall
    @walls[:north] = true
	end

	def unset_north_wall
    @walls[:north] = false
	end

	def set_west_wall
    @walls[:west] = true
	end

	def unset_west_wall
    @walls[:west] = false
	end

  def add_reverse_neighbor original_direction, neighbor
    directions  = [%w(west east), %w(north south), %w(up down), %w(out in)].collect {|a| a.collect &:to_sym }
    reverse_map = directions.inject({}) {|h,a| h[a.first] = a.last ; h[a.last] = a.first ; h }
    direction   = reverse_map[original_direction.to_sym] || "reverse_of_#{original_direction}".to_sym
    @neighbors[direction]=neighbor
  end
  protected :add_reverse_neighbor

	def add_neighbor direction, neighbor
		@neighbors[direction]=neighbor
    neighbor.add_reverse_neighbor direction, self
	end

	def del_neighbor direction
		@neighbors[direction]=nil
	end

	def dump
		[@neighbors,@walls]
	end

  def to_s
    "#{@neighbors.length} neighbors - #{@walls.inspect}"
  end

  def inspect
    "Cell(##{object_id.to_s(16)} #{to_s}"
  end
end

class Maze
	def initialize length, width
		raise "length and width must be fixnums" unless length.class==Fixnum and width.class==Fixnum

		first_cell=nil
		@board=[[]]
		(0...length).each {|l|
			@board[l] ||=[]
			(0...width).each{|w|
				@board[l][w]=cell=Cell.new
        @board[l-1][w].add_neighbor(:south, cell) unless l == 0
				@board[l][w-1].add_neighbor(:east,  cell) unless w == 0
			}
		}
		@board
	end
  attr_accessor :board
end
