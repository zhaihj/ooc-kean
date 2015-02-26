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

RasterMonochrome: class extends RasterPacked {
	bytesPerPixel: Int { get { 1 } }
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
		this apply(ColorConvert fromMonochrome(action))
	}
	apply: func ~yuv (action: Func(ColorYuv)) {
		this apply(ColorConvert fromMonochrome(action))
	}
	apply: func ~monochrome (action: Func(ColorMonochrome)) {
		end := this buffer pointer + this buffer size
		rowLength := this size width
		for (row: SSizeT in this buffer pointer as SSizeT..end as SSizeT) {
//			"RasterMonochrome apply ~monochrome, end of line at #{row}" println()
			rowEnd := row + rowLength
			for (source:SSizeT in row..rowEnd)
				action((source as ColorMonochrome*)@)
			row += this stride - 1
		}
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
					c := this[x,y]
					o := (other as RasterMonochrome)[x,y]
					if (c distance(o) > 0) {
						maximum := o
						minimum := o
						for (otherY in Int maximum~two(0, y - 2)..Int minimum~two(y + 3, this size height))
							for (otherX in Int maximum~two(0, x - 2)..Int minimum~two(x + 3, this size width))
								if (otherX != x || otherY != y) {
									pixel := (other as RasterMonochrome)[otherX, otherY]
									if (maximum y < pixel y)
										maximum y = pixel y;
									else if (minimum y > pixel y)
										minimum y = pixel y
								}
						distance := 0.0f;
						if (c y < minimum y)
							distance += (minimum y - c y) as Float squared()
						else if (c y > maximum y)
							distance += (c y - maximum y) as Float squared()
						result += distance sqrt();
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
		requiredComponents := 1 
        data := StbImage load(filename toCString(), x&, y&, n&, requiredComponents)
        if(!data){ Exception new(StbImage failureReason() toString()) throw() }
		buffer := ByteBuffer new(x * y * requiredComponents)
		// FIXME: Find a better way to do this using Dispose() or something
		memcpy(buffer pointer, data, x * y * requiredComponents)
		StbImage free(data)
		This new(buffer, IntSize2D new(x, y))
	}
	save: func (filename: String) -> Int {
		StbImage writePng(filename, this size width, this size height, this bytesPerPixel, this buffer pointer, this size width * this bytesPerPixel)
	}
	convertFrom: static func(original: RasterImage) -> This {
		result := This new(original)
		row := result buffer pointer as UInt8*
		rowLength := result stride
		rowEnd := row + rowLength
		destination := row
		f := func (color: ColorMonochrome) {
			(destination as ColorMonochrome*)@ = color
			destination += 1
			if (destination >= rowEnd) {
				row += result stride
				destination = row
				rowEnd = row + rowLength
			}
		}
		original apply(f)

        result
	}

	operator [] (x, y: Int) -> ColorMonochrome {
		this isValidIn(x, y) ? ColorMonochrome new(this buffer pointer[y * this stride + x]) : ColorMonochrome new(0)
	}
	operator []= (x, y: Int, value: ColorMonochrome) { ((this buffer pointer + y * this stride) as ColorMonochrome* + x)@ = value }
}
