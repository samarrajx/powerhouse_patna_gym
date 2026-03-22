import React from 'react';

const Logo = ({ size = 40, className = '' }) => {
  return (
    <div className={`logo-container ${className}`} style={{ width: size, height: size, borderRadius: '20%', overflow: 'hidden', flexShrink: 0 }}>
      <img src="/logo.jpg" alt="PH Gym Logo" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
    </div>
  );
};

export default Logo;
