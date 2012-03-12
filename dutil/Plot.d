module dutil.Plot;

import tango.math.Math;

import gnuplot;

void CubeHelix(double gray, out double red, out double green, out double blue, double gamma = 1.0, 
               double s = 0.5, double r = -1.5, double h = 1.0, double min_x = 0.2, double max_x = 1.0)
{
	double color_func(double p0, double p1, double x)
	{
		// Apply gamma factor to emphasise low or high intensity values
		auto xg = pow((x * (max_x - min_x) + min_x), gamma);

		// Calculate amplitude and angle of deviation from the black
		// to white diagonal in the plane of constant
		// perceived intensity.
		auto a = h * xg * (1 - xg) / 2;

		auto phi = 2 * PI * (s / 3 + r * x);

		return xg + a * (p0 * cos(phi) + p1 * sin(phi));
	}
	
	red = color_func(-0.14861, 1.78277, gray);
    green = color_func(-0.29227, -0.90649, gray);
    blue = color_func(1.97294, 0.0, gray);
}

void SetCubeHelix(C3DPlot plot, size_t num_divs = 100)
{
	assert(num_divs > 1);
	size_t n = 0;
	bool cube_helix_good(out double gray, out double r, out double g, out double b)
	{
		gray = (cast(double)n) / (num_divs - 1);
		CubeHelix(gray, r, g, b, 1.0, 0.5, -0.8, 2, 0.2, 1);
		n++;
		return n < num_divs;
	}
	
	plot.Palette(&cube_helix_good);
}
