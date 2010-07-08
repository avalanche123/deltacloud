#
# Copyright (C) 2009  Red Hat, Inc.
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.  The
# ASF licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations
# under the License.

require 'deltacloud/base_driver'
require 'deltacloud/drivers/rackspace/rackspace_client'

module Deltacloud
  module Drivers
    module Rackspace

class RackspaceDriver < Deltacloud::BaseDriver

  feature :instances, :user_name

  def hardware_profiles(credentials, opts = nil)
    racks = new_client( credentials )
    results = racks.list_flavors.map do |flav|
      HardwareProfile.new(flav["id"].to_s) do
        architecture 'x86_64'
        memory flav["ram"].to_i
        storage flav["disk"].to_i
      end
    end
    filter_hardware_profiles(results, opts)
  end

  def images(credentials, opts=nil)
    racks = new_client( credentials )
    results = racks.list_images.map do |img|
      Image.new( {
                   :id=>img["id"].to_s,
                   :name=>img["name"],
                   :description => img["name"] + " " + img["status"] + "",
                   :owner_id=>"root",
                   :architecture=>'x86_64'
                 } )
    end
    results.sort_by{|e| [e.description]}
    results = filter_on( results, :id, opts )
    results
  end

  #rackspace does not at this stage have realms... its all US/TX, all the time (at least at time of writing)
  def realms(credentials, opts=nil)
    [Realm.new( {
      :id=>"us",
      :name=>"United States",
      :state=> "AVAILABLE"
    } )]
  end

  def reboot_instance(credentials, id)
    racks = new_client(credentials)
    racks.reboot_server(id)
  end

  def stop_instance(credentials, id)
    destroy_instance(credentials, id)
  end

  def destroy_instance(credentials, id)
    racks = new_client(credentials)
    racks.delete_server(id)
  end


  #
  # create instance. Default to flavor 1 - really need a name though...
  # In rackspace, all flavors work with all images.
  #
  def create_instance(credentials, image_id, opts)
    racks = new_client( credentials )
    hwp_id = opts[:hwp_id] || 1
    name = Time.now.to_s
    if (opts[:name]) then name = opts[:name] end
    convert_srv_to_instance(racks.start_server(image_id, hwp_id, name))
  end

  #
  # Instances
  #
  def instances(credentials, opts=nil)
    racks = new_client(credentials)
    instances = []
    if (opts.nil?)
      instances = racks.list_servers.map do |srv|
        convert_srv_to_instance(srv)
      end
    else
      instances << convert_srv_to_instance(racks.load_server_details(opts[:id]))
    end
    instances = filter_on( instances, :id, opts )
    instances = filter_on( instances, :state, opts )
    instances
  end


  def convert_srv_to_instance(srv)
    status = srv["status"] == "ACTIVE" ? "RUNNING" : "PENDING"
    inst = Instance.new(:id => srv["id"].to_s,
                        :owner_id => "root",
                        :realm_id => "us")
    inst.name = srv["name"]
    inst.state = srv["status"] == "ACTIVE" ? "RUNNING" : "PENDING"
    inst.actions = instance_actions_for(inst.state)
    inst.image_id = srv["imageId"].to_s
    inst.instance_profile = InstanceProfile.new(srv["flavorId"].to_s)
    if srv["addresses"]
      inst.public_addresses  = srv["addresses"]["public"]
      inst.private_addresses = srv["addresses"]["private"]
    end
    inst
  end

  def new_client(credentials)
    RackspaceClient.new(credentials.user, credentials.password)
  end

  define_instance_states do
    start.to( :pending )          .on( :create )

    pending.to( :running )        .automatically

    running.to( :running )        .on( :reboot )
    running.to( :shutting_down )  .on( :stop )

    shutting_down.to( :stopped )  .automatically

    stopped.to( :finish )         .automatically
  end

end

    end
  end
end
