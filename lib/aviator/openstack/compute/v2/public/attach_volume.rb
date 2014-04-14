module Aviator

  define_request :attach_volume, inherit: [:openstack, :common, :v2, :public, :base] do

    meta :service, :compute

    link 'documentation',
         'http://docs.openstack.org/api/openstack-compute/2/content/POST_os-floating-ips-v2_AddFloatingIP_v2__tenant_id__servers__server_id__action_ext-os-floating-ips.html'

    param :server_id, required: true
    param :volume_id, required: true
    param :device,   required: true

    def body
      p = {
        "volumeAttachment" => {
          "volumeId" => params[:volume_id],
          "device" => params[:device]
        }
      }

      p
    end

    def headers
      super
    end


    def http_method
      :post
    end


    def url
      "#{ base_url }/servers/#{ params[:server_id] }/action"
    end

  end

end