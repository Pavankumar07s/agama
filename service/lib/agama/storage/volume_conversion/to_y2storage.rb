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

require "y2storage"
require "agama/storage/volume"

module Agama
  module Storage
    module VolumeConversion
      # Volume conversion to Y2Storage format.
      class ToY2Storage
        # @param volume [Agama::Storage::Volume]
        def initialize(volume)
          @volume = volume
        end

        # Performs the conversion to Y2Storage format.
        #
        # @return [Y2Storage::VolumeSpecification]
        def convert # rubocop:disable Metrics/AbcSize
          Y2Storage::VolumeSpecification.new({}).tap do |target|
            target.device = volume.device
            target.separate_vg_name = volume.separate_vg_name
            target.mount_point = volume.mount_path
            target.mount_options = volume.mount_options.join(",")
            target.proposed = true
            target.proposed_configurable = !volume.outline.required?
            target.fs_types = volume.outline.filesystems
            target.fs_type = volume.fs_type
            target.weight = 100
            target.adjust_by_ram = volume.outline.adjust_by_ram?

            sizes_conversion(target)
            btrfs_conversion(target)
          end
        end

      private

        # @return [Agama::Storage::Volume]
        attr_reader :volume

        # @param target [Y2Storage::VolumeSpecification]
        def sizes_conversion(target)
          auto = volume.auto_size?

          target.ignore_fallback_sizes = !auto
          target.ignore_snapshots_sizes = !auto

          target.min_size = auto ? volume.outline.base_min_size : volume.min_size
          target.max_size = auto ? volume.outline.base_max_size : volume.max_size
        end

        # @param target [Y2Storage::VolumeSpecification]
        def btrfs_conversion(target)
          target.snapshots = volume.btrfs.snapshots?
          target.snapshots_configurable = volume.outline.snapshots_configurable?
          target.snapshots_size = volume.outline.snapshots_size
          target.snapshots_percentage = volume.outline.snapshots_percentage
          target.subvolumes = volume.btrfs.subvolumes
          target.btrfs_default_subvolume = volume.btrfs.default_subvolume
          target.btrfs_read_only = volume.btrfs.read_only?
        end
      end
    end
  end
end
