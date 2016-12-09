require 'rollout'
require 'rollout_ui2'
require 'redis'

USERS = [ { id: 1,
            text: "jimi.lepisto@example.com",
            picture: "https://randomuser.me/api/portraits/thumb/men/21.jpg" },
          { id: 2,
            text: "emilia.koskinen@example.com",
            picture: "https://randomuser.me/api/portraits/thumb/women/61.jpg" },
          { id: 3,
            text: "ron.perez@example.com",
            picture: "https://randomuser.me/api/portraits/thumb/men/96.jpg" },
          { id: 4,
            text: "tim.carpenter@example.com",
            picture: "https://randomuser.me/api/portraits/thumb/men/79.jpg" },
          { id: 5,
            text: "aatu.marttila@example.com",
            picture: "https://randomuser.me/api/portraits/thumb/men/36.jpg" },
          { id: 6,
            text: "طاها.نكونظر@example.com",
            picture: "https://randomuser.me/api/portraits/thumb/men/86.jpg" },
          { id: 7,
            text: "gabrielle.chu@example.com",
            picture: "https://randomuser.me/api/portraits/thumb/women/40.jpg" },
          { id: 8,
            text: "hans.philipp@example.com",
            picture: "https://randomuser.me/api/portraits/thumb/men/49.jpg" },
          { id: 9,
            text: "isabella.harris@example.com",
            picture: "https://randomuser.me/api/portraits/thumb/women/32.jpg" },
          { id: 10,
            text: "stacey.olson@example.com",
            picture: "https://randomuser.me/api/portraits/thumb/women/3.jpg" } ]

class User
  def self.find_by_id(ids)
    USERS.select { |it| ids.include?(it[:id].to_s) }
  end

  def self.search(query, page)
    result = USERS.select { |it| %r{#{query}} =~ it[:text] }
    per_page = 3
    {
      results: result[(page-1) * per_page...page * per_page],
      per_page: per_page,
      total_count: result.count
    }
  end
end

RolloutUi2.wrap(Rollout.new(Redis.new)).with_finder(User)

RolloutUi2::Server.use Rack::Auth::Basic do |user, pass|
  user == pass
end

run Rack::URLMap.new(
  # "/" => Your::App.new,
  "/rollout" => RolloutUi2::Server
)
