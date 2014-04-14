require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/compute/v2/public/attach_volume' do

    def create_request(session_data = get_session_data, &block)
      block ||= lambda do |params|
                  params[:server_id] = 'randompassword'
                  params[:volume_id]   = 'testvolumeID'
                  params[:device] = '/dev/vdc'
                end
      klass.new(session_data, &block)
    end


    def get_session_data
      session.send :auth_info
    end


    def helper
      Aviator::Test::RequestHelper
    end


    def klass
      @klass ||= helper.load_request('openstack', 'compute', 'v2', 'public', 'attach_volume.rb')
    end


    def session
      unless @session
        @session = Aviator::Session.new(
                     config_file: Environment.path,
                     environment: 'openstack_member'
                   )
        @session.authenticate
      end

      @session
    end


    validate_attr :anonymous? do
      klass.anonymous?.must_equal false
    end


    validate_attr :api_version do
      klass.api_version.must_equal :v2
    end


    validate_attr :body do
      request = create_request

      klass.body?.must_equal true
      request.body?.must_equal true
      request.body.wont_be_nil
    end


    validate_attr :endpoint_type do
      klass.endpoint_type.must_equal :public
    end


    validate_attr :headers do
      headers = { 'X-Auth-Token' => get_session_data[:access][:token][:id] }

      request = create_request

      request.headers.must_equal headers
    end


    validate_attr :http_method do
      create_request.http_method.must_equal :post
    end


    validate_attr :optional_params do
      klass.optional_params.must_equal []
    end


    validate_attr :required_params do
      klass.required_params.must_equal [:server_id, :volume_id, :device]
    end


    validate_attr :url do
      session_data = get_session_data
      service_spec = session_data[:access][:serviceCatalog].find{|s| s[:type] == 'compute' }
      server_id    = 'testdummyID'
      volume_id    = 'testvolumeID'
      device       = '/dev/vdc'
      url          = "#{ service_spec[:endpoints][0][:publicURL] }/servers/#{ server_id }/action"

      request = create_request do |params|
        params[:server_id]  = server_id
        params[:volume_id]  = volume_id
        params[:device]     = device
      end

      request.url.must_equal url
    end


    validate_response 'valid parameters are provided' do
      session.compute_service.request :create_volume

      server_list_response  = session.compute_service.request :list_servers
      volume_list_response  = session.volume_service.request  :list_volumes

      server_id  = server_list_response.body[:servers][-1][:id]
      volume_id  = volume_list_response.body[:volumes][-1][:id]
      device     = '/dev/vdc'

      response = session.compute_service.request :attach_volume do |params|
        params[:server_id]  = server_id
        params[:volume_id]  = volume_id
        params[:device]     = device
      end

      response.status.must_equal 200
      response.body.wont_be_nil
      response.body[:volumeAttachment].wont_be_nil
      response.headers.wont_be_nil
    end


    validate_response 'non existent server is provided' do
      response = session.compute_service.request :attach_volume do |params|
        params[:server_id]  = 'serverDoesntExist'
        params[:volume_id]  = 'testvolumeID'
        params[:device]     = '/dev/vdc'
      end

      response.status.must_equal 404
      response.headers.wont_be_nil
      response.body["itemNotFound"].wont_be_nil
      response.body["itemNotFound"]["message"].must_equal "The resource could not be found."
    end


    validate_response 'non existent volume is provided' do
      list_response = session.volume_service.request :list_volumes

      response = session.compute_service.request :attach_volume do |params|
        params[:server_id]  = list_response.body[:servers].first[:id]
        params[:volume_id]  = 'volumeDoesntExist'
        params[:device]     = '/dev/vdc'
      end

      response.status.must_equal 404
      response.headers.wont_be_nil
      response.body["itemNotFound"].wont_be_nil
      response.body["itemNotFound"]["message"].must_equal "Volume could not found"
    end

  end

end