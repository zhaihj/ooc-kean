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
import StbImage
import Image
import Color

RasterBgr: class extends RasterPacked {
	bytesPerPixel: Int { get { 3 } }
	init: func ~allocate (size: IntSize2D, align := 0, verticalAlign := 0) { super(size, align, verticalAlign) }
	init: func ~fromByteBuffer (buffer: ByteBuffer, size: IntSize2D, align := 0, verticalAlign := 0) { super(buffer, size, align, verticalAlign) }
	init: func ~fromRasterImage (original: RasterImage) { super(original)	}
	create: func (size: IntSize2D) -> Image { This new(size) }
	copy: func -> This {
		result := This new(this)
		this buffer copyTo(result buffer)
		result
	}
	apply: func ~bgr (action: Func(ColorBgr)) {
		end := this buffer pointer + this buffer size
		rowLength := this size width
		for (row in this buffer pointer as SSizeT..end as SSizeT) {
			rowEnd := row + rowLength
			for (source in row..rowEnd) {
				action((source as ColorBgr*)@)
				source += 2
			}
			row += this stride - 1
		}
	}
	apply: func ~yuv (action: Func(ColorYuv)) {
		this apply(ColorConvert fromBgr(action))
	}
	apply: func ~monochrome (action: Func(ColorMonochrome)) {
		this apply(ColorConvert fromBgr(action))
	}
	distance: func (other: Image) -> Float {
		result := 0.0f
		if (!other)
			result = Float maximumValue
//		else if (!other instanceOf?(This))
//			FIXME
//		else if (this size != other size)
//			FIXME
		else {
			for (y in 0..this size height)
				for (x in 0..this size width) {
					c := this[x, y]
					o := (other as RasterBgr)[x, y]
					if (c distance(o) > 0) {
						maximum := o
						minimum := o
						for (otherY in Int maximum~two(0, y - this distanceRadius)..Int minimum~two(y + 1 + this distanceRadius, this size height))
							for (otherX in Int maximum~two(0, x - this distanceRadius)..Int minimum~two(x + 1 + this distanceRadius, this size width))
								if (otherX != x || otherY != y) {
									pixel := (other as RasterBgr)[otherX, otherY]
									if (maximum blue < pixel blue)
										maximum blue = pixel blue
									else if (minimum blue > pixel blue)
										minimum blue = pixel blue
									if (maximum green < pixel green)
										maximum green = pixel green
									else if (minimum green > pixel green)
										minimum green = pixel green
									if (maximum red < pixel red)
										maximum red = pixel red
									else if (minimum red > pixel red)
										minimum red = pixel red
								}
						distance := 0.0f;
						if (c blue < minimum blue)
							distance += (minimum blue - c blue) as Float squared()
						else if (c blue > maximum blue)
							distance += (c blue - maximum blue) as Float squared()
						if (c green < minimum green)
							distance += (minimum green - c green) as Float squared()
						else if (c green > maximum green)
							distance += (c green - maximum green) as Float squared()
						if (c red < minimum red)
							distance += (minimum red - c red) as Float squared()
						else if (c red > maximum red)
							distance += (c red - maximum red) as Float squared()
						result += (distance) sqrt() / 3;
					}
				}
			result /= ((this size width squared() + this size height squared()) as Float sqrt())
		}
	}
//	FIXME
//	openResource(assembly: ???, name: String) {
//		Image openResource
//	}
	open: static func (filename: String) -> This {
		x, y, n: Int
		requiredComponents := 3
		data := StbImage load(filename, x&, y&, n&, requiredComponents)
        if(!data){ Exception new(StbImage failureReason() toString()) throw() }
		result := This new(IntSize2D new(x, y))
		memcpy(result buffer pointer, data, x * y * requiredComponents)
		// FIXME: Find a better way to do this using Dispose() or something
		StbImage free(data)
		result
	}
	save: func (filename: String) -> Int {
		StbImage writePng(filename, this size width, this size height, this bytesPerPixel, this buffer pointer, this buffer size)
	}
	convertFrom: static func(original: RasterImage) -> This {
		result := This new(original)
		row := result buffer pointer
		rowLength := result size width
		rowEnd := row as ColorBgr* + rowLength
		destination := row as ColorBgr*
		f := func (color: ColorBgr) {
			(destination as ColorBgr*)@ = color
			destination += 1
			if (destination >= rowEnd) {
				row += result stride
				destination = row as ColorBgr*
				rowEnd = row as ColorBgr* + rowLength
			}
		}
		original apply(f)
		result
	}
	operator [] (x, y: Int) -> ColorBgr { this isValidIn(x, y) ? ((this buffer pointer + y * this stride) as ColorBgr* + x)@ : ColorBgr new(0, 0, 0) }
	operator []= (x, y: Int, value: ColorBgr) { ((this buffer pointer + y * this stride) as ColorBgr* + x)@ = value }
}
