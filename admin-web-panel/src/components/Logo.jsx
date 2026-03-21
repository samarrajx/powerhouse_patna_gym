import React from 'react';

const Logo = ({ size = 40, className = '', color = 'var(--lime, #C8FA00)' }) => {
  return (
    <div className={`logo-container ${className}`} style={{ width: size, height: size, color }}>
      <svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg" style={{ display: 'block', width: '100%', height: '100%' }}>
        <style>
          {`
            @keyframes rotate-gear {
              from { transform: rotate(0deg); }
              to { transform: rotate(360deg); }
            }
            .gear-outer {
              transform-origin: center;
              animation: rotate-gear 20s linear infinite;
            }
          `}
        </style>

        {/* Outer Gear teeth */}
        <circle 
          cx="100" cy="100" r="94" 
          fill="none" 
          stroke="currentColor" 
          strokeWidth="6" 
          strokeDasharray="12 4.4" 
          className="gear-outer"
        />
        <circle cx="100" cy="100" r="88" fill="none" stroke="currentColor" strokeWidth="2" />
        <circle cx="100" cy="100" r="82" fill="none" stroke="currentColor" strokeWidth="1" strokeDasharray="2 3" opacity="0.5" />

        {/* Stars */}
        <text x="32" y="104" font-family="Space Grotesk, sans-serif" font-weight="800" fill="currentColor" fontSize="12">★</text>
        <text x="168" y="104" font-family="Space Grotesk, sans-serif" font-weight="800" fill="currentColor" fontSize="12">★</text>

        {/* Text */}
        <text font-family="Space Grotesk, sans-serif" font-weight="800" fill="currentColor" fontSize="13" letterSpacing="1" style={{ textTransform: 'uppercase' }}>
          <textPath href="#circlePathTop" startOffset="50%" textAnchor="middle">Power House Gym</textPath>
        </text>
        <text font-family="Space Grotesk, sans-serif" font-weight="800" fill="currentColor" fontSize="10" letterSpacing="2.5" style={{ textTransform: 'uppercase' }}>
          <textPath href="#circlePathBottom" startOffset="50%" textAnchor="middle">Dare To Be Great</textPath>
        </text>

        {/* High-Detail Barbell */}
        <g transform="translate(100, 100)" fill="currentColor">
          <rect x="-45" y="-1.5" width="90" height="3" />
          <rect x="-34" y="-14" width="6" height="28" rx="1" />
          <rect x="-26" y="-10" width="3" height="20" rx="0.5" />
          <rect x="28" y="-14" width="6" height="28" rx="1" />
          <rect x="23" y="-10" width="3" height="20" rx="0.5" />
          <circle cx="-45" cy="0" r="2.5" />
          <circle cx="45" cy="0" r="2.5" />
        </g>
      </svg>
    </div>
  );
};

export default Logo;
