extends Node3D

var material: ShaderMaterial

func _ready():
	# Create a plane mesh
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(200, 200)
	plane_mesh.subdivide_depth = 200
	plane_mesh.subdivide_width = 200

	var ocean_instance = MeshInstance3D.new()
	ocean_instance.mesh = plane_mesh

	# Shader
	var shader = Shader.new()
	shader.code = """
		shader_type spatial;
		render_mode cull_disabled;

		uniform float time;
		uniform float wave_height = 1.0;
		uniform float wave_speed = 0.2;
		uniform float wave_scale = 0.1;
		uniform sampler2D noise_tex : source_color;

		void vertex() {
			// Use noise texture to displace height
			vec2 uv = VERTEX.xz * wave_scale + vec2(time * wave_speed, time * wave_speed * 0.5);
			float n = texture(noise_tex, uv).r; // sample red channel of noise
			VERTEX.y += (n - 0.5) * 2.0 * wave_height;

			// Approximate normal from noise for lighting
			vec2 offset = vec2(0.01, 0.0);
			float n_x = texture(noise_tex, uv + offset.xy).r;
			float n_z = texture(noise_tex, uv + offset.yx).r;
			NORMAL = normalize(vec3(n - n_x, 0.5, n - n_z));
		}

		void fragment() {
			ALBEDO = vec3(0.0, 0.5, 0.8); // stylized ocean color
			ROUGHNESS = 0.3;
			METALLIC = 0.0;
		}
	"""

	material = ShaderMaterial.new()
	material.shader = shader

	# Create a noise texture (uses Godot's FastNoiseLite under the hood)
	var noise = NoiseTexture2D.new()
	noise.noise = FastNoiseLite.new()
	noise.noise.seed = randi()
	noise.noise.frequency = 0.8
	noise.noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.noise.fractal_octaves = 4
	noise.noise.fractal_gain = 0.5
	noise.noise.fractal_lacunarity = 2.0
	noise.seamless = true

	material.set_shader_parameter("noise_tex", noise)

	ocean_instance.material_override = material
	add_child(ocean_instance)

	set_process(true)


func _process(delta: float) -> void:
	if material:
		material.set_shader_parameter("time", Time.get_ticks_msec() / 100000.0)
