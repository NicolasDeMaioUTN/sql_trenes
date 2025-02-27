import React, { useState } from 'react';
import { Map, View } from 'ol';
import TileLayer from 'ol/layer/Tile';
import OSM from 'ol/source/OSM';
import { fromLonLat } from 'ol/proj';
import 'ol/ol.css';

function Mapa({ urlWms }) {
  const [map, setMap] = useState(null);

  useEffect(() => {
    if (urlWms) {
      const newMap = new Map({
        target: 'map',
        layers: [
          new TileLayer({
            source: new OSM(),
          }),
          new TileLayer({
            source: new TileWMS({
              url: urlWms,
              params: { LAYERS: 'tu_capa', TILED: true },
            }),
          }),
        ],
        view: new View({
          center: fromLonLat([-58.3816, -34.6037]),  // Centrar en Buenos Aires
          zoom: 10,
        }),
      });
      setMap(newMap);
    }
  }, [urlWms]);

  return <div id="map" style={{ width: '100%', height: '500px' }}></div>;
}

export default Mapa;