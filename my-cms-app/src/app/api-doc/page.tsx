// src/app/api-doc/page.tsx

'use client';

import { useState } from 'react';
import dynamic from 'next/dynamic';
import 'swagger-ui-react/swagger-ui.css';

const SwaggerUI = dynamic(() => import('swagger-ui-react'), { ssr: false });

export default function ApiDocPage() {
  const [showWarning, setShowWarning] = useState(true);
  const isReadOnlyMode = process.env.NEXT_PUBLIC_READONLY_MODE === 'true';

  return (
    <section className="container mx-auto">
      {/* คำเตือน */}
      {showWarning && (
        <div className={`p-4 mb-4 rounded-lg border-2 ${
          isReadOnlyMode 
            ? 'bg-blue-50 border-blue-500' 
            : 'bg-yellow-50 border-yellow-500'
        }`}>
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <h3 className="font-bold text-lg mb-2">
                {isReadOnlyMode ? '🔒 Read-Only Mode' : '⚠️ คำเตือน'}
              </h3>
              {isReadOnlyMode ? (
                <p className="text-sm">
                  API อยู่ในโหมด <strong>Read-Only</strong> - ไม่สามารถเปลี่ยนแปลงข้อมูลได้<br/>
                  สามารถทดสอบ GET requests ได้ตามปกติ
                </p>
              ) : (
                <div className="text-sm space-y-2">
                  <p className="font-semibold text-yellow-800">
                    การกด "Execute" ใน Swagger UI จะส่ง Request จริงไปที่ API
                  </p>
                  <ul className="list-disc list-inside space-y-1 text-yellow-700">
                    <li><strong>POST/PUT/DELETE</strong> จะเปลี่ยนแปลงข้อมูลใน Database จริง</li>
                    <li>แนะนำให้ใช้ Database แยกสำหรับ Development</li>
                    <li>หรือเปิด Read-Only Mode ด้วย NEXT_PUBLIC_READONLY_MODE=true</li>
                  </ul>
                </div>
              )}
            </div>
            <button
              onClick={() => setShowWarning(false)}
              className="ml-4 text-gray-500 hover:text-gray-700"
            >
              ✕
            </button>
          </div>
        </div>
      )}

      {/* Swagger UI */}
      <SwaggerUI url="/api/api-doc" />
      
      {/* Footer Info */}
      <div className="mt-8 p-4 bg-gray-100 rounded-lg text-sm text-gray-600">
        <p><strong>Environment:</strong> {process.env.NODE_ENV}</p>
        <p><strong>Read-Only Mode:</strong> {isReadOnlyMode ? '✅ Enabled' : '❌ Disabled'}</p>
      </div>
    </section>
  );
}