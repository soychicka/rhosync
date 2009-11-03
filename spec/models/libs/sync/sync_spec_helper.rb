
def triple(*args) 
  id = args.shift
  raise "Illegal triplet" unless args.size.even?
  pairs = {}
  args.each_slice(2) {|pair| pairs[pair[0]] = pair[1] }
  {id => pairs}
end

def triples(*args) 
  args.inject({}) { |merged, triplet| merged.merge(triplet) }
end
