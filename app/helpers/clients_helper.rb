module ClientsHelper
  def setup_client(client_id)
    # setup client & user association if it doesn't exist
    if client_id and client_id != 'client_id'
      @client = Client.find_by_client_id(client_id)
      if @client.nil?
        @client = Client.new
        @client.client_id = client_id
      end
      @client.user ||= current_user
      @client.save
    end
    @client
  end
end
