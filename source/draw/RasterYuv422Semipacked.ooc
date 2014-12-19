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
use ooc-base
import math
import structs/ArrayList
import RasterPacked
import RasterImage
import RasterMonochrome
import Image
import Color
import RasterBgr
import StbImage
import io/File
import io/FileReader
import io/Reader
import io/FileWriter
import io/BinarySequence

RasterYuv422Semipacked: class extends RasterPacked {
	bytesPerPixel: Int { get { 2 } }
	init: func ~fromSize (size: IntSize2D) { this init(size, CoordinateSystem Default, IntShell2D new()) }
	init: func ~fromStuff (size: IntSize2D, coordinateSystem: CoordinateSystem, crop: IntShell2D) {
		bufSize := RasterPacked calculateLength(size, this bytesPerPixel)
		super(ByteBuffer new(bufSize), size, coordinateSystem, crop)
	}
//	 FIXME but only if we really need it
//	init: func ~fromByteArray (data: UInt8*, size: IntSize2D) { this init(ByteBuffer new(data), size) }
	init: func ~fromByteBuffer (buffer: ByteBufferAbstract, size: IntSize2D) {
		super(buffer, size, CoordinateSystem Default, IntShell2D new())
	}
	init: func ~fromEverything (buffer: ByteBufferAbstract, size: IntSize2D, coordinateSystem: CoordinateSystem, crop: IntShell2D) {
		super(buffer, size, coordinateSystem, crop)
	}
	init: func ~fromRasterYuv420 (original: This) { super(original) }
	init: func ~fromRasterImage (original: RasterImage) {
		this init(original size, original coordinateSystem, original crop)
//		"RasterYuv420 init ~fromRasterImage, original: (#{original size}), this: (#{this size}), y stride #{this y stride}" println()
		y := 0
		x := 0
		width := this size width
		row := this pointer as UInt8*
		destination := row
//		C#: original.Apply(color => *((Color.Bgra*)destination++) = new Color.Bgra(color, 255));
		f := func (color: ColorYuv) {
			if (x % 2) {
				destination@ = color v
			} else {
				destination@ = color u
			}
			destination += 1
			destination@ = color y
			destination += 1
			x += 1
			if (x >= width) {
				x = 0
				y += 1

				row += this stride
				destination = row
			}
		}
		original apply(f)
	}
	create: func (size: IntSize2D) -> Image {
		result := This new(size)
		result crop = this crop
		result wrap = this wrap
		result
	}
	copy: func -> This {
//  	"copying..." println()
		This new(this)
	}
	apply: func ~bgr (action: Func(ColorBgr)) {
		this apply(ColorConvert fromYuv(action))
	}
	apply: func ~yuv (action: Func (ColorYuv)) {
		row := this pointer as UInt8*
		source := row
		width := this size width
		height := this size height

		for (y in 0..height) {
			for (x in 0..width) {
				action(ColorYuv new((source+1)@, (source - 2*(x % 2))@, (source + 2*((x + 1) % 2))@))
				source += 2
			}
			row += this stride
		}
	}
	apply: func ~monochrome (action: Func(ColorMonochrome)) {
		this apply(ColorConvert fromYuv(action))
	}

//	FIXME
//	openResource(assembly: ???, name: String) {
//		Image openResource
//	}
	operator [] (x, y: Int) -> ColorYuv {
		result := ColorYuv new()
		if (this isValidIn(x, y)) {
			index := (this pointer + y * this stride + x * this bytesPerPixel) as ColorMonochrome* // U or V value
			result = ColorYuv new((index + 1)@ y, (index - 2*(x % 2))@ y, (index + 2*((x + 1) % 2))@ y)
		}
		result
	}
	operator []= (x, y: Int, value: ColorYuv) {
		if (this isValidIn(x, y)) {
			index := (this pointer + y * this stride + x * this bytesPerPixel) as ColorMonochrome* // U or V value
			(index + 1)@ = ColorMonochrome new(value y)
			(index - 2*(x % 2))@ = ColorMonochrome new(value u)
			(index - 2*((x + 1) % 2))@ = ColorMonochrome new(value v)
		}
	}
	__destroy__: func {
		this buffer decreaseReferenceCount()
	}
	open: static func (filename: String) -> This {
		x, y, n: Int
		requiredComponents := 3
		data := StbImage load(filename, x&, y&, n&, requiredComponents)
		buffer := ByteBuffer new(x * y * requiredComponents)
		// FIXME: Find a better way to do this using Dispose() or something
		memcpy(buffer pointer, data, x * y * requiredComponents)
		StbImage free(data)
		bgr := RasterBgr new(buffer, IntSize2D new(x, y))
		result := This new(bgr)
		bgr decreaseReferenceCount()
		return result
	}
	save: func (filename: String) {
		bgr := RasterBgr new(this)
		bgr save(filename)
		bgr decreaseReferenceCount()
	}
	saveBin: func (filename: String) {
		fileWriter := FileWriter new(filename)
		fileWriter write(this buffer pointer as Char*, this buffer size)
		fileWriter close()
	}
	openBin: static func (filename: String, width: Int, height: Int) -> This {
		fileReader := FileReader new(FStream open(filename, "rb"))
		bytes := width * height * 2
		data: UInt8* = gc_malloc_atomic(bytes)
		fileReader read((data as Char*), 0, bytes)
		fileReader close()
		fileReader free()
		buffer := ByteBuffer new(bytes, data as UInt8*)
		result := This new(buffer, IntSize2D new(width, height))
		buffer decreaseReferenceCount()
		result
	}
}