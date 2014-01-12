#import "quaternion.hxx"

class line {
public:
    quaternion	origin;
    quaternion  direction;

    inline void setDirection(quaternion dest)
    {
        direction = (dest - origin).normalized();
    }
    
    inline line(void) : origin(0, 0, 0, 0), direction(0, 0, 0, 0)
    {
        
    }
    
    inline line(quaternion o, quaternion dest)
    {
        origin = o;
        setDirection(dest);
    }
    inline ~line() {}

    inline quaternion quaternionAtDistance(double const &dist) const
    {
        return origin + direction * dist;
    }
};
