# ===== Default : Default
$LOAD_PATH << File.expand_path('/home/sid/vecmath/lib', __FILE__)
require 'vecmath'
require 'forwardable'

# Here we use the JRubyArt Vec2D class, and not toxis Vec2D. We avoid using
# ToxicLibsSupport, by using our own GfxRender to translate Vec2D to vertices.
# Further we use the power of ruby (metaprogramming) to make Branch enumerable
# and use Forwardable to define which enumerable methods we want to use.
visor_class :Branch do
  include Enumerable
  extend Forwardable
  def_delegators(:@children, :<<, :each, :length)
  # variance angle for growth direction per time step
  THETA = Math::PI / 6
  # max segments per branch
  MAX_LEN = 100
  # max recursion limit
  MAX_GEN = 3
  # branch chance per time step
  BRANCH_CHANCE = 0.05
  # branch angle variance
  BRANCH_THETA = Math::PI / 3
  attr_reader :position, :dir, :path, :children, :xbound, :speed, :ybound, :app

  def initialize(pos, dir, speed)
    @position = pos
    @dir = dir
    @speed = speed
    @path = []
    @children = []
    @xbound = Boundary.new(0, 400)
    @ybound = Boundary.new(0, 400)
    path << pos
  end

  def run
    grow
    display
  end

  private

  # NB: use of both rotate! (changes original) rotate (returns a copy) of Vec2D
  def grow
    check_bounds(position + (dir * speed)) if path.length < MAX_LEN
    @position += (dir * speed)
    dir.rotate!(rand(-0.5..0.5) * THETA)
    path << position
    if (length < MAX_GEN) && (rand < BRANCH_CHANCE)
      branch_dir = dir.rotate(rand(-0.5..0.5) * BRANCH_THETA)
      self << Branch.new(position.copy, branch_dir, speed * 0.99)
    end
    each(&:grow)
  end

  def display
    @renderer ||= GfxRender.new(graphics)
    beginShape
    stroke(255)
    no_fill
    path.each { |vec| vec.to_vertex(@renderer) }
    endShape
    each(&:display)
  end

  def check_bounds(pos)
    dir.x *= -1 if xbound.exclude? pos.x
    dir.y *= -1 if ybound.exclude? pos.y
  end
end

# we are looking for excluded values
Boundary = Struct.new(:lower, :upper) do
  def exclude?(val)
    !(lower...upper).cover? val
  end
end

@root = Branch.new(
    Vec2D.new(0, height / 2),
    Vec2D.new(1, 0),
    10.0
)

def draw
  background(0)
  root.run
end
