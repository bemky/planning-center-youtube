class HomeController < ApplicationController
  def index
  end

  def test_auth
    @strategies = OmniAuth.strategies.map(&:name)
    render plain: "Available OmniAuth strategies: #{@strategies.inspect}"
  end
end