class Array ; def random ; return nil if length.zero? ; entries[rand(length)] ; end ; end

class Cell
  
	def initialize walls=nil
		@walls= {}
		@neighbors= {}
    @walked_on=false
	end

	attr_reader :neighbors, :walls, :walked_on 

	def set_wall direction, state = true, both = true
    direction = direction.to_sym
    neighbors[direction].set_wall reverse_dir(direction), false, state if both
    @walls[direction] = state
	end

	def unset_wall direction, both = true
    set_wall direction, false, both
	end

  def passable? direction, both = false
    direction = direction.to_sym
    raise "No such neighbor - #{direction} from #{inspect}" unless @neighbors[direction]
    return false unless neighbors[direction].passable? reverse_dir(direction), false if both
    !@walls[direction] # if there isn't a wall, you're free to go
  end

  def reverse_dir direction
    direction = direction.to_sym
    @reverse_map ||= begin
      directions = [%w(east west), %w(north south), %w(up down), %w(in out)].collect {|a| a.collect &:to_sym }
      directions.inject({}) {|h,a| h[a.first] = a.last ; h[a.last] = a.first ; h }
    end
    @reverse_map[direction] || "reverse_of_#{direction}".to_sym
  end

	def add_neighbor direction, neighbor, reverse = false
    direction = direction.to_sym
    neighbor.add_neighbor direction, self, true unless reverse
    direction = reverse_dir(direction) if reverse
		@neighbors[direction] = neighbor
    @walls[direction]     = true
	end

	def del_neighbor direction, reverse = false
    direction = direction.to_sym
    if reverse
      direction = reverse_dir(direction)
    else
      raise "No such neighbor - #{direction} from #{inspect}" unless @neighbors[direction]
      @neighbors[direction].del_neighbor direction, true
    end
		[@neighbors, @walls].each {|h| h.delete direction }
	end

  def unvisited?
    walls.all? {|dir,wall| wall }
  end

  def unvisited_neighbors
    neighbors.select {|dir,cell| cell.unvisited? }
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

  def display
    w = '#' # wall character
    north = (walls.member?(:north) && passable?(:north, false)) ? (walked_on==true ? '.' : ' ') : w
    west  = (walls.member?(:west ) && passable?(:west , false)) ? (walked_on==true ? '.' : ' ') : w
    [ [w,   north],
      [west, (walked_on==true ? '.' : ' ')] ]
  end
  def walk_on
    walked_on=true
  end
end

class Maze
	def initialize length, width
    @length, @width = length, width
		raise "length and width must be fixnums" unless length.class==Fixnum and width.class==Fixnum

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

  def generate
    l, w = rand(length), rand(width)
    crawl( board[l][w] ) {|cell,dir| cell.unset_wall dir }
  end
  def crawl(starting_cell)
    list=[starting_cell]
    begin
      cell=list.last
      unvisited= cell.unvisited_neighbors
      if unvisited.empty?
        list.pop
      else
        dir, other = unvisited.random
        yield cell, dir
        list << other
      end
    end while !list.empty?
  end

  def display
    pad_char = '#' ; pad = pad_char * (width * 2 + 1)
    board.each {|cells|
      rows = cells.inject([]) {|rows, cell|
        output = cell.display
        output.each_with_index {|crow,i| (rows[i] ||= []) << crow }
        rows
      }
      rows = rows.collect {|row| "#{row.join}#{pad_char}" }
      puts rows.collect {|row| row }
    }
    puts pad
    nil
  end
  attr_reader :board, :length, :width
end
