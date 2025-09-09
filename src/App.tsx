import React, { useState } from 'react';
import { Plane, Search, Calendar, Users, MapPin, CreditCard, User, Menu, X, Shield, Clock, Star } from 'lucide-react';

interface Flight {
  id: string;
  airline: string;
  flightNumber: string;
  departure: {
    city: string;
    airport: string;
    time: string;
    date: string;
  };
  arrival: {
    city: string;
    airport: string;
    time: string;
    date: string;
  };
  duration: string;
  price: number;
  stops: number;
  aircraft: string;
  availableSeats: number;
}

const AnimatedPlane: React.FC = () => (
  <div className="absolute top-20 right-10 opacity-10">
    <div className="animate-pulse">
      <Plane size={120} className="text-blue-600 transform rotate-45" />
    </div>
  </div>
);

const FlightCard: React.FC<{ flight: Flight; onSelect: (flight: Flight) => void }> = ({ flight, onSelect }) => (
  <div className="bg-white rounded-2xl shadow-lg hover:shadow-xl transition-all duration-300 p-6 border border-gray-100 hover:border-blue-200">
    <div className="flex justify-between items-start mb-4">
      <div className="flex items-center space-x-3">
        <div className="w-12 h-12 bg-gradient-to-r from-blue-600 to-sky-500 rounded-full flex items-center justify-center">
          <Plane size={20} className="text-white" />
        </div>
        <div>
          <h3 className="font-semibold text-gray-800">{flight.airline}</h3>
          <p className="text-sm text-gray-500">{flight.flightNumber} • {flight.aircraft}</p>
        </div>
      </div>
      <div className="text-right">
        <p className="text-2xl font-bold text-blue-600">${flight.price.toLocaleString('es-CL')}</p>
        <p className="text-sm text-gray-500">por persona</p>
      </div>
    </div>

    <div className="flex items-center justify-between mb-4">
      <div className="flex-1">
        <p className="text-lg font-semibold text-gray-800">{flight.departure.time}</p>
        <p className="text-sm text-gray-600">{flight.departure.city}</p>
        <p className="text-xs text-gray-400">{flight.departure.airport}</p>
      </div>
      
      <div className="flex-1 flex flex-col items-center px-4">
        <p className="text-sm text-gray-500 mb-1">{flight.duration}</p>
        <div className="w-full h-px bg-gradient-to-r from-transparent via-blue-300 to-transparent relative">
          <div className="absolute top-0 left-1/2 transform -translate-x-1/2 -translate-y-1/2">
            <Plane size={14} className="text-blue-500 rotate-90" />
          </div>
        </div>
        <p className="text-xs text-gray-400 mt-1">
          {flight.stops === 0 ? 'Directo' : `${flight.stops} escala${flight.stops > 1 ? 's' : ''}`}
        </p>
      </div>

      <div className="flex-1 text-right">
        <p className="text-lg font-semibold text-gray-800">{flight.arrival.time}</p>
        <p className="text-sm text-gray-600">{flight.arrival.city}</p>
        <p className="text-xs text-gray-400">{flight.arrival.airport}</p>
      </div>
    </div>

    <div className="flex items-center justify-between">
      <div className="flex items-center space-x-4 text-sm text-gray-500">
        <span className="flex items-center space-x-1">
          <Users size={14} />
          <span>{flight.availableSeats} asientos</span>
        </span>
      </div>
      <button
        onClick={() => onSelect(flight)}
        className="bg-gradient-to-r from-blue-600 to-sky-500 hover:from-blue-700 hover:to-sky-600 text-white px-6 py-2 rounded-full font-medium transition-all duration-200 transform hover:scale-105"
      >
        Seleccionar
      </button>
    </div>
  </div>
);

const Header: React.FC = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  return (
    <header className="bg-white shadow-sm border-b border-gray-100">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-gradient-to-r from-blue-600 to-sky-500 rounded-xl flex items-center justify-center">
              <Plane size={20} className="text-white" />
            </div>
            <h1 className="text-xl font-bold bg-gradient-to-r from-blue-600 to-sky-500 bg-clip-text text-transparent">
              VuelaChile
            </h1>
          </div>

          <nav className="hidden md:flex items-center space-x-8">
            <a href="#" className="text-gray-700 hover:text-blue-600 font-medium transition-colors">Vuelos</a>
            <a href="#" className="text-gray-700 hover:text-blue-600 font-medium transition-colors">Hoteles</a>
            <a href="#" className="text-gray-700 hover:text-blue-600 font-medium transition-colors">Mis Reservas</a>
            <a href="#" className="text-gray-700 hover:text-blue-600 font-medium transition-colors">Check-in</a>
          </nav>

          <div className="hidden md:flex items-center space-x-4">
            <button className="flex items-center space-x-2 text-gray-700 hover:text-blue-600 font-medium transition-colors">
              <User size={20} />
              <span>Iniciar Sesión</span>
            </button>
          </div>

          <button
            className="md:hidden"
            onClick={() => setIsMenuOpen(!isMenuOpen)}
          >
            {isMenuOpen ? <X size={24} /> : <Menu size={24} />}
          </button>
        </div>
      </div>

      {isMenuOpen && (
        <div className="md:hidden bg-white border-t border-gray-100">
          <div className="px-4 py-4 space-y-3">
            <a href="#" className="block text-gray-700 hover:text-blue-600 font-medium">Vuelos</a>
            <a href="#" className="block text-gray-700 hover:text-blue-600 font-medium">Hoteles</a>
            <a href="#" className="block text-gray-700 hover:text-blue-600 font-medium">Mis Reservas</a>
            <a href="#" className="block text-gray-700 hover:text-blue-600 font-medium">Check-in</a>
            <button className="flex items-center space-x-2 text-gray-700 hover:text-blue-600 font-medium">
              <User size={20} />
              <span>Iniciar Sesión</span>
            </button>
          </div>
        </div>
      )}
    </header>
  );
};

const SearchForm: React.FC<{ onSearch: (params: any) => void }> = ({ onSearch }) => {
  const [searchParams, setSearchParams] = useState({
    from: 'Santiago (SCL)',
    to: 'Valparaíso (KNA)',
    departure: '2024-12-20',
    return: '2024-12-27',
    passengers: 1,
    tripType: 'roundtrip'
  });

  const handleSearch = () => {
    onSearch(searchParams);
  };

  return (
    <div className="bg-white rounded-3xl shadow-xl p-8 border border-gray-100">
      <div className="flex flex-wrap gap-4 mb-6">
        <label className="flex items-center space-x-2">
          <input
            type="radio"
            name="tripType"
            value="roundtrip"
            checked={searchParams.tripType === 'roundtrip'}
            onChange={(e) => setSearchParams({...searchParams, tripType: e.target.value})}
            className="w-4 h-4 text-blue-600"
          />
          <span className="text-gray-700 font-medium">Ida y vuelta</span>
        </label>
        <label className="flex items-center space-x-2">
          <input
            type="radio"
            name="tripType"
            value="oneway"
            checked={searchParams.tripType === 'oneway'}
            onChange={(e) => setSearchParams({...searchParams, tripType: e.target.value})}
            className="w-4 h-4 text-blue-600"
          />
          <span className="text-gray-700 font-medium">Solo ida</span>
        </label>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
        <div className="md:col-span-1">
          <label className="block text-sm font-medium text-gray-700 mb-2">Origen</label>
          <div className="relative">
            <MapPin size={18} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
            <select
              value={searchParams.from}
              onChange={(e) => setSearchParams({...searchParams, from: e.target.value})}
              className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="Santiago (SCL)">Santiago (SCL)</option>
              <option value="Valparaíso (KNA)">Valparaíso (KNA)</option>
              <option value="Concepción (CCP)">Concepción (CCP)</option>
              <option value="La Serena (LSC)">La Serena (LSC)</option>
              <option value="Temuco (ZCO)">Temuco (ZCO)</option>
            </select>
          </div>
        </div>

        <div className="md:col-span-1">
          <label className="block text-sm font-medium text-gray-700 mb-2">Destino</label>
          <div className="relative">
            <MapPin size={18} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
            <select
              value={searchParams.to}
              onChange={(e) => setSearchParams({...searchParams, to: e.target.value})}
              className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="Valparaíso (KNA)">Valparaíso (KNA)</option>
              <option value="Santiago (SCL)">Santiago (SCL)</option>
              <option value="Concepción (CCP)">Concepción (CCP)</option>
              <option value="La Serena (LSC)">La Serena (LSC)</option>
              <option value="Temuco (ZCO)">Temuco (ZCO)</option>
            </select>
          </div>
        </div>

        <div className="md:col-span-1">
          <label className="block text-sm font-medium text-gray-700 mb-2">Salida</label>
          <div className="relative">
            <Calendar size={18} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
            <input
              type="date"
              value={searchParams.departure}
              onChange={(e) => setSearchParams({...searchParams, departure: e.target.value})}
              className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
        </div>

        {searchParams.tripType === 'roundtrip' && (
          <div className="md:col-span-1">
            <label className="block text-sm font-medium text-gray-700 mb-2">Regreso</label>
            <div className="relative">
              <Calendar size={18} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
              <input
                type="date"
                value={searchParams.return}
                onChange={(e) => setSearchParams({...searchParams, return: e.target.value})}
                className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>
          </div>
        )}

        <div className="md:col-span-1">
          <label className="block text-sm font-medium text-gray-700 mb-2">Pasajeros</label>
          <div className="relative">
            <Users size={18} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
            <select
              value={searchParams.passengers}
              onChange={(e) => setSearchParams({...searchParams, passengers: parseInt(e.target.value)})}
              className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              {[1,2,3,4,5,6,7,8,9].map(num => (
                <option key={num} value={num}>{num} pasajero{num > 1 ? 's' : ''}</option>
              ))}
            </select>
          </div>
        </div>
      </div>

      <div className="mt-6 flex justify-center">
        <button
          onClick={handleSearch}
          className="bg-gradient-to-r from-blue-600 to-sky-500 hover:from-blue-700 hover:to-sky-600 text-white px-12 py-4 rounded-2xl font-semibold text-lg transition-all duration-200 transform hover:scale-105 flex items-center space-x-2"
        >
          <Search size={20} />
          <span>Buscar Vuelos</span>
        </button>
      </div>
    </div>
  );
};

const PaymentModal: React.FC<{ flight: Flight; isOpen: boolean; onClose: () => void }> = ({ flight, isOpen, onClose }) => {
  const [paymentMethod, setPaymentMethod] = useState('transbank');
  
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-3xl max-w-md w-full max-h-[90vh] overflow-y-auto">
        <div className="p-6">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-2xl font-bold text-gray-800">Confirmar Reserva</h2>
            <button onClick={onClose} className="text-gray-400 hover:text-gray-600">
              <X size={24} />
            </button>
          </div>

          <div className="bg-gray-50 rounded-2xl p-4 mb-6">
            <div className="flex items-center space-x-3 mb-3">
              <div className="w-8 h-8 bg-gradient-to-r from-blue-600 to-sky-500 rounded-full flex items-center justify-center">
                <Plane size={14} className="text-white" />
              </div>
              <div>
                <p className="font-semibold text-gray-800">{flight.airline}</p>
                <p className="text-sm text-gray-600">{flight.flightNumber}</p>
              </div>
            </div>
            <div className="flex justify-between items-center">
              <div>
                <p className="text-sm text-gray-600">{flight.departure.city} → {flight.arrival.city}</p>
                <p className="text-xs text-gray-500">{flight.departure.time} - {flight.arrival.time}</p>
              </div>
              <p className="text-xl font-bold text-blue-600">${flight.price.toLocaleString('es-CL')}</p>
            </div>
          </div>

          <div className="space-y-4 mb-6">
            <h3 className="font-semibold text-gray-800">Método de Pago</h3>
            
            <label className="flex items-center space-x-3 p-4 border-2 border-gray-200 rounded-xl cursor-pointer hover:border-blue-300 transition-colors">
              <input
                type="radio"
                name="payment"
                value="transbank"
                checked={paymentMethod === 'transbank'}
                onChange={(e) => setPaymentMethod(e.target.value)}
                className="w-4 h-4 text-blue-600"
              />
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 bg-red-500 rounded flex items-center justify-center">
                  <CreditCard size={16} className="text-white" />
                </div>
                <div>
                  <p className="font-medium text-gray-800">Transbank</p>
                  <p className="text-sm text-gray-600">Tarjeta de débito o crédito</p>
                </div>
              </div>
            </label>

            <label className="flex items-center space-x-3 p-4 border-2 border-gray-200 rounded-xl cursor-pointer hover:border-blue-300 transition-colors">
              <input
                type="radio"
                name="payment"
                value="khipu"
                checked={paymentMethod === 'khipu'}
                onChange={(e) => setPaymentMethod(e.target.value)}
                className="w-4 h-4 text-blue-600"
              />
              <div className="flex items-center space-x-3">
                <div className="w-8 h-8 bg-green-500 rounded flex items-center justify-center">
                  <Shield size={16} className="text-white" />
                </div>
                <div>
                  <p className="font-medium text-gray-800">Khipu</p>
                  <p className="text-sm text-gray-600">Transferencia bancaria</p>
                </div>
              </div>
            </label>
          </div>

          <button className="w-full bg-gradient-to-r from-blue-600 to-sky-500 hover:from-blue-700 hover:to-sky-600 text-white py-4 rounded-2xl font-semibold text-lg transition-all duration-200 transform hover:scale-105">
            Proceder al Pago
          </button>

          <div className="mt-4 flex items-center justify-center space-x-2 text-sm text-gray-500">
            <Shield size={16} />
            <span>Pago 100% seguro y encriptado</span>
          </div>
        </div>
      </div>
    </div>
  );
};

function App() {
  const [showFlights, setShowFlights] = useState(false);
  const [selectedFlight, setSelectedFlight] = useState<Flight | null>(null);
  const [showPayment, setShowPayment] = useState(false);

  const sampleFlights: Flight[] = [
    {
      id: '1',
      airline: 'LATAM Airlines',
      flightNumber: 'LA 144',
      departure: { city: 'Santiago', airport: 'SCL', time: '08:30', date: '2024-12-20' },
      arrival: { city: 'Valparaíso', airport: 'KNA', time: '09:45', date: '2024-12-20' },
      duration: '1h 15m',
      price: 89000,
      stops: 0,
      aircraft: 'Airbus A320',
      availableSeats: 23
    },
    {
      id: '2',
      airline: 'Sky Airline',
      flightNumber: 'H2 2851',
      departure: { city: 'Santiago', airport: 'SCL', time: '14:20', date: '2024-12-20' },
      arrival: { city: 'Valparaíso', airport: 'KNA', time: '15:30', date: '2024-12-20' },
      duration: '1h 10m',
      price: 75000,
      stops: 0,
      aircraft: 'Airbus A319',
      availableSeats: 12
    },
    {
      id: '3',
      airline: 'JetSMART',
      flightNumber: 'JA 8041',
      departure: { city: 'Santiago', airport: 'SCL', time: '18:45', date: '2024-12-20' },
      arrival: { city: 'Valparaíso', airport: 'KNA', time: '19:55', date: '2024-12-20' },
      duration: '1h 10m',
      price: 65000,
      stops: 0,
      aircraft: 'Airbus A320neo',
      availableSeats: 45
    }
  ];

  const handleSearch = (params: any) => {
    setShowFlights(true);
  };

  const handleFlightSelect = (flight: Flight) => {
    setSelectedFlight(flight);
    setShowPayment(true);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-sky-50 to-white">
      <Header />
      
      <main className="relative">
        <AnimatedPlane />
        
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
          {!showFlights ? (
            <div className="text-center mb-12">
              <h1 className="text-5xl md:text-6xl font-bold text-gray-800 mb-6">
                Vuela por <span className="bg-gradient-to-r from-blue-600 to-sky-500 bg-clip-text text-transparent">Chile</span>
              </h1>
              <p className="text-xl text-gray-600 mb-12 max-w-2xl mx-auto">
                Descubre los destinos más increíbles de Chile con las mejores tarifas y el servicio que te mereces.
              </p>
              
              <SearchForm onSearch={handleSearch} />

              <div className="mt-16 grid grid-cols-1 md:grid-cols-3 gap-8">
                <div className="text-center p-6">
                  <div className="w-16 h-16 bg-gradient-to-r from-blue-600 to-sky-500 rounded-2xl flex items-center justify-center mx-auto mb-4">
                    <Clock size={32} className="text-white" />
                  </div>
                  <h3 className="text-xl font-semibold text-gray-800 mb-2">Reserva Rápida</h3>
                  <p className="text-gray-600">Encuentra y reserva tu vuelo en menos de 3 minutos</p>
                </div>

                <div className="text-center p-6">
                  <div className="w-16 h-16 bg-gradient-to-r from-blue-600 to-sky-500 rounded-2xl flex items-center justify-center mx-auto mb-4">
                    <Shield size={32} className="text-white" />
                  </div>
                  <h3 className="text-xl font-semibold text-gray-800 mb-2">Pago Seguro</h3>
                  <p className="text-gray-600">Transbank y Khipu para máxima seguridad</p>
                </div>

                <div className="text-center p-6">
                  <div className="w-16 h-16 bg-gradient-to-r from-blue-600 to-sky-500 rounded-2xl flex items-center justify-center mx-auto mb-4">
                    <Star size={32} className="text-white" />
                  </div>
                  <h3 className="text-xl font-semibold text-gray-800 mb-2">Mejor Precio</h3>
                  <p className="text-gray-600">Garantizamos las mejores tarifas del mercado</p>
                </div>
              </div>
            </div>
          ) : (
            <div>
              <div className="flex items-center justify-between mb-8">
                <div>
                  <h2 className="text-3xl font-bold text-gray-800">Vuelos Disponibles</h2>
                  <p className="text-gray-600 mt-1">Santiago → Valparaíso • 20 Dic 2024 • 1 pasajero</p>
                </div>
                <button
                  onClick={() => setShowFlights(false)}
                  className="bg-gray-100 hover:bg-gray-200 text-gray-700 px-6 py-3 rounded-xl font-medium transition-colors"
                >
                  Nueva Búsqueda
                </button>
              </div>

              <div className="space-y-4">
                {sampleFlights.map(flight => (
                  <FlightCard key={flight.id} flight={flight} onSelect={handleFlightSelect} />
                ))}
              </div>
            </div>
          )}
        </div>
      </main>

      {selectedFlight && (
        <PaymentModal
          flight={selectedFlight}
          isOpen={showPayment}
          onClose={() => {
            setShowPayment(false);
            setSelectedFlight(null);
          }}
        />
      )}
    </div>
  );
}

export default App;