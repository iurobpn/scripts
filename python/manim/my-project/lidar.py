from manim import *

class LidarScene(MovingCameraScene):
    def construct(self):
        L = 10  # canvas side length (your coord range will be 0..L)
        C=L/2.0
        canvas = Square(side_length=L, fill_color=WHITE, fill_opacity=1, stroke_width=0)
        self.add(canvas)

        # Show only the canvas (no black outside)
        # self.camera_frame.set_width(L)
        # self.camera_frame.move_to(canvas)
        frame = self.camera.frame
        frame.set(width=L, height=L)
        frame.move_to(canvas)

        # Canvas coords helper: bottom-left corner is (0,0)
        origin= canvas.get_corner(DL)
        def P(x, y):  # canvas (x,y) -> scene point
            return origin + np.array([x, y, 0])

        # EXAMPLES -------------------------------------------------------------

        # 1) Square with bottom-left at (0.5, 0.5), side 1
        sq = Square(side_length=1, stroke_width=0, fill_color=BLACK, fill_opacity=1)
        sq.move_to(P(5, 5))  # move by its center

        # 2) Circle centered at (4.5, 4.5), radius 0.6
        # circ = Circle(radius=0.25, stroke_width=0.1, fill_color=DARK_BLUE, fill_opacity=1)
        # circ.move_to(P(0.5, 0.5))
        robot = Robot(origin=origin)
        robot.shift(np.array([0.5,0.5,0]))

        lidar = SemiCircle(radius=5, origin=origin)
        lidar.shift(np.array([0.5,0.5,0]))

        # 3) Polygon using your points (all inside the canvas coords)
        # pts = [P(0,0), P(0,1), P(1,1), P(1.5,0.5), P(1.5,0)]
        # poly = Polygon(*pts, stroke_width=0, fill_color=GREEN, fill_opacity=0.6)
        
        self.add(sq, robot)
        self.add(lidar)
        # self.wait(2)

class SemiCircle(VMobject):
    def __init__(self, origin=np.array([0,0,0]), radius=1,xcenter=0,ycenter=0,theta=0,npts=180, **kwargs):
        super().__init__(**kwargs)
        self.radius = radius
        self.xcenter = xcenter
        self.ycenter = ycenter
        self.theta  = theta
        self.npts = npts
        self.pts = None
        obj = self.get_semi_circle()
        self.add(obj)
        # --- Align automatically to canvas origin ---
        local_origin = self.get_center()
        shift_vec = np.array(origin) + local_origin
        super().move_to(shift_vec)   # call parent shift, not overridden version


    # def move_to(self, point):
    #     self.move_to(self.origin + point + self.obj.get_center())


    # def move_to(self, point):
    #     self.move_to(self.origin + point + self.obj.get_center())


    def get_semi_circle(self):
        """
            generate semicircle points
        """
        PI = np.pi
        r = self.radius
        x = r * np.cos(np.linspace(0, PI, self.npts))
        y = r * np.sin(np.linspace(0, PI, self.npts))
        self.pts = np.array([x, y, np.zeros(self.npts)]).T
        semicirc = Polygon(*self.pts, color=DARK_BLUE, stroke_opacity=1, stroke_width=1, fill_color=BLUE, fill_opacity=0.5)

        return semicirc

class Robot(VMobject):
    def __init__(self, origin=np.array([0,0,0]), circle_radius=0.25, polygon_points=None,
                 ellipse1_size=(0.125, 0.2), ellipse2_size=(0.125, 0.2),
                 **kwargs):
        super().__init__(**kwargs)

        # Default polygon if none provided
        if polygon_points is None:
            polygon_points = [[0,0,0],[1,0,0],[0.5,1,0]]


        # Polygon
        # polygon = Polygon(*polygon_points, color=GREEN, fill_opacity=0.5)

        # Ellipses
        # ellipse1 = Ellipse(width=ellipse1_size[0], height=ellipse1_size[1],
        #                    color=BLACK, fill_opacity=1).shift(np.array([-0.25,0,0]))
        # ellipse2 = Ellipse(width=ellipse2_size[0], height=ellipse2_size[1],
        #                    color=BLACK, fill_opacity=1).shift(np.array([0.25,0,0]))

        wheel_corner_radius = 0.02
        wheel_width = 0.1
        wheel_height = 0.2
        wheel_left = RoundedRectangle(
            corner_radius=wheel_corner_radius,   # radius of the corners
            width=wheel_width,             # width of the rectangle
            height=wheel_height,            # height of the rectangle
            color=BLACK,
            fill_opacity=1
        ).shift(np.array([-0.25,0,0]))
        wheel_right = RoundedRectangle(
            corner_radius=wheel_corner_radius,   # radius of the corners
            width=wheel_width,             # width of the rectangle
            height=wheel_height,            # height of the rectangle
            color=BLACK,
            fill_opacity=1
        ).shift(np.array([0.25,0,0]))
        # Circle
        circle = Circle(radius=0.25, stroke_width=0.1, fill_color=DARK_BLUE, fill_opacity=1)

        # Add all parts
        self.add(wheel_right, wheel_left, circle)

        local_origin = self.get_center()
        shift_vec = np.array(origin) + local_origin
        super().move_to(shift_vec)   # call parent shift, not overridden version

        # --- Store an "origin" reference (bottom-left corner of bounding box) ---

