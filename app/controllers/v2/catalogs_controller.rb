class V2::CatalogsController < V2::BaseController
  def show
    render json: {
      services: services.map {|service| service.to_hash }
    }
  end

  private

  def services
    Service.all
  end
end
