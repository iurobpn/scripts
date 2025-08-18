from manim import *

class SquareToCircle(Scene):
    def construct(self):
        circle = Circle()  # create a circle
        circle.set_fill(PINK, opacity=0.5)  # set color and transparency

        square = Square()  # create a square
        square.flip(RIGHT)  # flip horizontally
        square.rotate(-3 * TAU / 8)  # rotate a certain amount

        self.play(Create(square))  # animate the creation of the square
        self.play(Transform(square, circle))  # interpolate the square into the circle
        self.play(FadeOut(square))  # fade out animation

class CreateCircle(Scene):
    def construct(self):
        circle = Circle()  # create a circle
        circle.set_fill(PINK, opacity=0.5)  # set the color and transparency
        self.play(Create(circle))  # show the circle on screen


class SquareAndCircle(Scene):
    def construct(self):
        circle = Circle()  # create a circle
        circle.set_fill(PINK, opacity=0.5)  # set the color and transparency

        square = Square()  # create a square
        square.set_fill(BLUE, opacity=0.5)  # set the color and transparency

        square.next_to(circle, LEFT, buff=0.1)  # set the position
        self.play(Create(circle), Create(square))  # show the shapes on screen

class AnimatedSquareToCircle(Scene):
    def construct(self):
        circle = Circle()  # create a circle
        square = Square()  # create a square

        self.play(Create(square))  # show the square on screen
        self.play(square.animate.rotate(PI / 4))  # rotate the square
        self.play(Transform(square, circle))  # transform the square into a circle
        self.play(
            square.animate.set_fill(PINK, opacity=0.5)
        )  # color the circle on screen


class DifferentRotations(Scene):
    def construct(self):
        left_square = Square(color=BLUE, fill_opacity=0.7).shift(2 * LEFT)
        right_square = Square(color=GREEN, fill_opacity=0.7).shift(2 * RIGHT)
        self.play(
            left_square.animate.rotate(PI), Rotate(right_square, angle=PI), run_time=2
        )
        self.wait()

class TwoTransforms(Scene):
    def transform(self):
        a = Circle()
        b = Square()
        c = Triangle()
        self.play(Transform(a, b))
        self.play(Transform(a, c))
        self.play(FadeOut(a))

    def replacement_transform(self):
        a = Circle()
        b = Square()
        c = Triangle()
        self.play(ReplacementTransform(a, b))
        self.play(ReplacementTransform(b, c))
        self.play(FadeOut(c))

    def construct(self):
        self.transform()
        self.wait(0.5)  # wait for 0.5 seconds
        self.replacement_transform()


class AnimateExample(Scene):
    def construct(self):
        square = Square().set_fill(RED, opacity=1.0)
        self.add(square)

        # animate the change of color
        self.play(square.animate.set_fill(WHITE))
        self.wait(1)

        # animate the change of position and the rotation at the same time
        self.play(square.animate.shift(UP).rotate(PI / 3))
        self.wait(1)


class RunTime(Scene):
    def construct(self):
        square = Square()
        self.add(square)
        self.play(square.animate.shift(UP), run_time=3)
        self.wait(1)

class PolygonExample(Scene):
    def construct(self):
        # Define the points
        p1 = [0, 0, 0]
        p2 = [0, 1, 0]
        p3 = [1, 1, 0]
        p4 = [1.5, 0.5, 0]
        p5 = [1.5, 0, 0]

        # Create a polygon VMobject
        polygon = Polygon(p1, p2, p3, p4, p5, color=BLUE, fill_opacity=0.5)

        # Add to the scene
        self.play(Create(polygon))
        self.wait(2)


class PolygonMorph(Scene):
    def construct(self):
        # Initial polygon points
        p1 = [0, 0, 0]
        p2 = [0, 1, 0]
        p3 = [1, 1, 0]
        p4 = [1.5, 0.5, 0]
        p5 = [1.5, 0, 0]

        polygon1 = Polygon(p1, p2, p3, p4, p5, color=BLUE, fill_opacity=0.5)

        # A second polygon with modified points
        q1 = [0, 0, 0]
        q2 = [0.5, 1.5, 0]
        q3 = [1.5, 1, 0]
        q4 = [2, 0.5, 0]
        q5 = [1.2, -0.3, 0]

        polygon2 = Polygon(q1, q2, q3, q4, q5, color=GREEN, fill_opacity=0.5)

        # Show first polygon
        self.play(Create(polygon1))
        self.wait(1)

        # Morph into the new polygon
        # self.play(Transform(polygon1, polygon2))
        self.play(polygon1.animate.become(polygon2))
        self.wait(2)


class PolyInstantChange(Scene):
    def construct(self):
        p1 = Polygon([0,0,0],[0,1,0],[1,1,0],[1.5,0.5,0],[1.5,0,0],
                     color=BLUE, fill_opacity=0.5)
        q1 = Polygon([0,0,0],[0.5,1.5,0],[1.5,1,0],[2,0.5,0],[1.2,-0.3,0],
                     color=GREEN, fill_opacity=0.5)

        self.add(p1)
        self.wait(1)

        # Instant switch
        p1.become(q1)
        self.wait(1)


class LidarScene(Scene):
    def construct(self):
        square = Square(side_length=2, color=WHITE, fill_opacity=1, stroke_width=0)
        # Move its center to (5,5)
        # square.shift(RIGHT*5 + UP*5)
        # square.set_x(5)
        # square.set_y(5)
        # square.set_points(square.get_points() + np.array([5, 5, 0]))
        # self.camera.move_to(square.get_center())
        # square.shift([5, 5, 0])
        self.add(square)

        # circle = Circle()  # create a circle
        # circle.set_fill(PINK, opacity=0.5)  # set color and transparency
        # circle.move_to([0, 0, 0])
        # self.add(circle)


class WhiteCanvasDemo(MovingCameraScene):
    def construct(self):
        L = 10  # canvas side length (your coord range will be 0..L)
        C=L/2.0
        canvas = Square(side_length=L, fill_color=WHITE, fill_opacity=1, stroke_width=0)
        self.add(canvas)

        # Show only the canvas (no black outside)
        # self.camera_frame.set_width(L)
        # self.camera_frame.move_to(canvas)
        frame = self.camera.frame
        frame.set_width(L)
        frame.set_height(L)
        frame.move_to(canvas)

        # Canvas coords helper: bottom-left corner is (0,0)
        bl = canvas.get_corner(DL)
        def P(x, y):  # canvas (x,y) -> scene point
            return bl + np.array([x, y, 0])

        # EXAMPLES -------------------------------------------------------------

        # 1) Square with bottom-left at (0.5, 0.5), side 1
        sq = Square(side_length=1, stroke_width=0, fill_color=BLACK, fill_opacity=1)
        sq.move_to(P(5, 5))  # move by its center

        # 2) Circle centered at (4.5, 4.5), radius 0.6
        circ = Circle(radius=0.25, stroke_width=0.1, fill_color=DARK_BLUE, fill_opacity=1)
        circ.move_to(P(0.5, 0.5))

        # 3) Polygon using your points (all inside the canvas coords)
        # pts = [P(0,0), P(0,1), P(1,1), P(1.5,0.5), P(1.5,0)]
        # poly = Polygon(*pts, stroke_width=0, fill_color=GREEN, fill_opacity=0.6)

        self.add(sq, circ)
        # self.wait(2)

