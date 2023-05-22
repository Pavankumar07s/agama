# frozen_string_literal: true

# Copyright (c) [2023] SUSE LLC
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, contact SUSE LLC.
#
# To contact SUSE LLC about this file by physical or electronic mail, you may
# find current contact information at www.suse.com.

require "dbus"
require "agama/dbus/base_object"
require "agama/dbus/storage/interfaces/drive"
require "agama/dbus/storage/interfaces/raid"
require "agama/dbus/storage/interfaces/multipath"
require "agama/dbus/storage/interfaces/md"
require "agama/dbus/storage/interfaces/block"
require "agama/dbus/storage/interfaces/partition_table"

module Agama
  module DBus
    module Storage
      # Class for D-Bus objects representing a storage device (e.g., Disk, Partition, VG, etc).
      #
      # The D-Bus object includes the required interfaces for the storage object that it represents.
      class Device < BaseObject
        # Constructor
        #
        # @param storage_device [Y2Storage::Device] Storage device
        # @param path [::DBus::ObjectPath] Path for the D-Bus object
        # @param logger [Logger, nil]
        def initialize(storage_device, path, logger: nil)
          super(path, logger: logger)

          @storage_device = storage_device
          add_interfaces
        end

      private

        # @return [Y2Storage::Device]
        attr_reader :storage_device

        # Adds the required interfaces according to the storage object
        def add_interfaces # rubocop:disable Metrics/CyclomaticComplexity
          interfaces = []
          interfaces << Interfaces::Drive if drive?
          interfaces << Interfaces::Raid if storage_device.is?(:dm_raid)
          interfaces << Interfaces::Md if storage_device.is?(:md)
          interfaces << Interfaces::Multipath if storage_device.is?(:multipath)
          interfaces << Interfaces::Block if storage_device.is?(:blk_device)
          interfaces << Interfaces::PartitionTable if partition_table?

          interfaces.each { |i| singleton_class.include(i) }
        end

        # Whether the storage device is a drive
        #
        # Drive and disk device are very close concepts, but there are subtle differences. For
        # example, a MD RAID is never considered as a drive.
        #
        # TODO: Revisit the defintion of drive. Maybe some MD devices could implement the drive
        #   interface if hwinfo provides useful information for them.
        #
        # @return [Boolean]
        def drive?
          storage_device.is?(:disk, :dm_raid, :multipath, :dasd) && storage_device.is?(:disk_device)
        end

        # Whether the storage device has a partition table
        #
        # @return [Boolean]
        def partition_table?
          storage_device.is?(:blk_device) && storage_device.partition_table?
        end
      end
    end
  end
end
