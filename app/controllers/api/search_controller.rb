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
  end
end
