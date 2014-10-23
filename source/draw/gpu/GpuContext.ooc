//
// Copyright (c) 2011-2014 Simon Mika <simon@mika.se>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.
use ooc-math
use ooc-draw
import GpuImage, GpuMonochrome, GpuUv, GpuBgr, GpuBgra, GpuYuv420Semiplanar, GpuYuv420Planar, GpuImageBin, GpuSurfaceBin, GpuSurface
GpuContext: abstract class {
	_imageBin: GpuImageBin
	_surfaceBin: GpuSurfaceBin
	init: func {
		this _imageBin = GpuImageBin new()
		this _surfaceBin = GpuSurfaceBin new()
	}

	createMonochrome: abstract func (size: IntSize2D) -> GpuMonochrome
	createBgr: abstract func (size: IntSize2D) -> GpuBgr
	createBgra: abstract func (size: IntSize2D) -> GpuBgra
	createUv: abstract func (size: IntSize2D) -> GpuUv
	createYuv420Semiplanar: abstract func (size: IntSize2D) -> GpuYuv420Semiplanar
	createYuv420Planar: abstract func (size: IntSize2D) -> GpuYuv420Planar
	createGpuImage: abstract func (rasterImage: RasterImage) -> GpuImage
	update: abstract func
	recycle: abstract func ~image (gpuImage: GpuImage)
	recycle: abstract func ~surface (surface: GpuSurface)
	getImage: abstract func (type: GpuImageType, size: IntSize2D) -> GpuImage
	getSurface: abstract func -> GpuSurface
	toRaster: abstract func (gpuImage: GpuImage) -> RasterImage
}
