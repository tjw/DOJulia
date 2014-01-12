#import <OmniGameMath/quaternion.hxx>

class line {
public:
    quaternion	origin;
    quaternion  direction;

    inline void setDirection(quaternion dest)
    {
        direction = (dest - origin).normalized();
    }
         
    inline line(quaternion o, quaternion dest)
    {
        origin = o;
        setDirection(dest);
    }

    inline quaternion quaternionAtDistance(double const &dist) const
    {
        return origin + direction * dist;
    }
};
