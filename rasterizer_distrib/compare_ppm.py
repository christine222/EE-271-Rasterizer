from PIL import Image
my_image = Image.open("sv_out.ppm")
my_image.save("sv_out.jpg")
print("my_image format", my_image.format)
print("my_image mode", my_image.mode)
print("my_image size", my_image.size)

ref_image = Image.open("/afs/ir/class/ee271/project/vect/vec_271_02_sv_ref.ppm")
ref_image.save("vec_271_02_sv_ref.jpg")
print("ref_image format", ref_image.format)
print("ref_image mode", ref_image.mode)
print("ref_image size", ref_image.size)

my_pixels = list(my_image.getdata())
ref_pixels = list(ref_image.getdata())

for i in range(len(my_pixels)):
    if my_pixels[i] != ref_pixels[i]:
        print(i, i/800, i % 800, my_pixels[i], ref_pixels[i])
        ref_pixels[i] = (255, 0, 0)

highlight_image = Image.new("RGB", ref_image.size)
highlight_image.putdata(ref_pixels)
highlight_image.save('highlight.jpg')
