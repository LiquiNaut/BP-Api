module Api
  class SearchController < ActionController::API
    def search
      @entity = LegalEntity.find_by(ico: params['ico'].to_s)

      render json: @entity, include: [addresses: {include: [:country, :municipality]}]
    end

    def tax_rep
      @entity = LegalEntity.find_by(ic_dph: params['ic_dph'].to_s)

      render json: @entity, include: [addresses: {include: [:country, :municipality]}]
    end

    def search_by_name
      @entities = LegalEntity.where("CONCAT(first_name, ' ', last_name) ILIKE :search OR entity_name ILIKE :search", search: "%#{params[:search]}%").limit(10)

      render json: @entities, include: [addresses: {include: [:country, :municipality]}]
    end

  end
end
