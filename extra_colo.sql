--------------------------------------------------------------------
----------------------------------1---------------------------------
--DiasMora

    -- DocCliente  (Nivel 0)--->    EIEIDE  --->  '19364433'

    -- ClasCartera  (Nivel 0)---->   cat_col   --->  Está en cero 
    
    
    --- EIECLA  --- >  Tiene un valor de 2 //////  En Staging Homologación se llama CatColombia.

'UPDATE H
SET DiasMoraAlineado = M.MaxDiasMora
FROM Staging.Homologacion H
INNER JOIN (
    SELECT DocCliente, ClasCartera, MAX(DiasMora) AS MaxDiasMora
    FROM Staging.Homologacion
    WHERE CodigoPais = 147
    GROUP BY DocCliente, ClasCartera
) AS M
ON H.DocCliente = M.DocCliente AND H.ClasCartera = M.ClasCartera
WHERE H.CodigoPais = 147;
GO
'
--prueba bjhbj
---------------------------------------------------------------------
--------------------------------1------------------------------------

--PorcProvHomologadaColombia   --->     Proc_Prov_hom  :
	--ClasCartera  0->     EIECLA
	--ValorCapitalCOP  0  ->	 EIEVCP	    ->  (Tiene algunos valores de cero en la muestra de ZonaGold Colombia)  Afecta
	--TotalProvisionCapitalAjustePais 0  ->   PROV_AJUS   (actualmente tiene un cero quemado)
	--TotalProvNormaColombia   ->  0  Prov_Ttl_N_Col  (actualmente se envía en cero)  Afecta
	


'UPDATE
    Staging.Homologacion
SET
    PorcProvHomologadaColombia= CASE
        WHEN ClasCartera = 3 THEN TotalProvNormaColombia / ValorCapitalCOP
        ELSE TotalProvisionCapitalAjustePais / TotalProvNormaColombia
    END
WHERE
    CodigoPais = 148
GO
'



-------------------------------------------------------------------------
------------------------------------1------------------------------------

--CapitalGarantizado    ------>     Capital_Garan

	--ValGarTipo3HipotecaCOP  0  ->  SI032    ----> Campo poblado con 4 valores en su mayoria cero

	--ValorCapitalCOP 0  ->	 EIEVCP	   ---- > Campo poblado con diferentes valores, incluye cero


'UPDATE
  Staging.Homologacion
SET
  CapitalGarantizado = CASE
    WHEN ValGarTipo3HipotecaCOP = ValorCapitalCOP THEN ValorCapitalCOP
    ELSE ValGarTipo3HipotecaCOP
  END
WHERE
  CodigoPais = 147
GO
'


--------------------------------------------------------------------------
----------------------------------1---------------------------------------
--PorcProvNoGarantizada    --->     Prov_Part_No_Garan
	-- CalDefEndeudamiento  0 ->   EIECAL     ----> Campo poblado con tres valores : 'A', 'B' y 'C'


'UPDATE [Staging].[Homologacion]
SET PorcProvNoGarantizada =
CASE WHEN CalDefEndeudamiento = 'A' THEN 0.01
ELSE 1.0
END
WHERE CodigoPais = 147
GO
'




----------------------------------------------------------------------------
-----------------------------------------1-------------------------------------
--ProvisionGeneralPorc1 	---->    Prov_1_Porc
	-- ValorCapitalCOP   ---- > EIEVCP    ---- > Campo poblado con diferentes valores, incluye cero
	-- 
 

'UPDATE [Staging].[Homologacion]
SET ProvisionGeneralPorc1 = (ValorCapitalCOP*0.01)
WHERE CodigoPais = 147 AND ClasCartera = 3
GO
'



---------------------------------------------------------------------------
-------------------------------------2--------------------------------------

--SuspensionCausacion	 ---->      Susp_Caus

	--DiasMoraAlineado   1 ----->   EIEEDA     ----> Campo poblado con tres valores ( 0, 11 y 42 )


'UPDATE [Staging].[Homologacion]
SET SuspensionCausacion =
CASE WHEN ClasCartera = '2' AND DiasMoraAlineado > 60 THEN 'SI'
WHEN ClasCartera = '1' AND DiasMoraAlineado > 90 THEN 'SI'
WHEN ClasCartera = '3' AND DiasMoraAlineado > 90 THEN 'SI'
ELSE 'NO' END
WHERE CodigoPais = 147
GO
'




----------------------------------------------------------------------------
----------------------------------2-----------------------------------------

--RangoEdad  2---->  RengoEdad
    -- DiasMora  1---- >  DiasMora    --- >  EIEEDA     ----> Campo poblado con tres valores diferentes ( 0, 11 y 42 )

'UPDATE [Staging].[Homologacion]
SET RangoEdad =
CASE WHEN DiasMora = 0 THEN '0 dias'
 WHEN DiasMora BETWEEN 1 AND 30 THEN 'Entre 1 y 30'
 WHEN DiasMora BETWEEN 31 AND 60 THEN 'Entre 31 y 60'
 WHEN DiasMora BETWEEN 61 AND 90 THEN 'Entre 61 y 90'
 WHEN DiasMora BETWEEN 91 AND 120 THEN 'Entre 91 y 120'
 WHEN DiasMora BETWEEN 121 AND 180 THEN 'Entre 121 y 180'
 WHEN DiasMora > 180 THEN 'Mayor a 180'
END
WHERE CodigoPais = 147
GO
'
----------------------------------------------------------------------------
----------------------------------2----------------------------------------
--CapitalNoGarantizado   ----->    Capital_No_Garan

	--ValorCapitalCOP  0 ->    EIEVCP	   ---- > Campo poblado con diferentes valores, incluye cero
	--CapitalGarantizado 1   ->  Capital_Garan      ----> Campo que está en cero  

'UPDATE [Staging].[Homologacion]
SET CapitalNoGarantizado = ValorCapitalCOP-CapitalGarantizado
WHERE CodigoPais = 147
GO
'
----------------------------------------------------------------------------
---------------------------------2------------------------------------------

--PorcProviGarantizada     ---->    Prov_Part_Garan       

	-- CalDefEndeudamiento 0 ->   EIECAL       (CalDefEndeudamiento en Colombia, según el archivo 'ZonaGoldColombia' solo
					                          ---tiene las calificaciones  ->  A , B , C.  Podría no necesitarse DiasMoraAlineado.) 
	-- DiasMoraAlineado  1 -> EIEEDA    ----> Campo poblado con tres valores ( 0, 11 y 42 )

'UPDATE [Staging].[Homologacion]
SET PorcProviGarantizada =
CASE
 WHEN CalDefEndeudamiento = 'A' THEN 0.01
 WHEN CalDefEndeudamiento = 'B' THEN 0.032
 WHEN CalDefEndeudamiento = 'C' THEN 0.1
 WHEN CalDefEndeudamiento = 'D' THEN 0.2
 WHEN CalDefEndeudamiento = 'E' AND DiasMoraAlineado<1271 THEN 0.3
 WHEN CalDefEndeudamiento = 'E' AND DiasMoraAlineado>1270 AND DiasMoraAlineado<1636 THEN 0.6
 ELSE 1 END
 WHERE CodigoPais = 147
GO'



----------------------------------------------------------------------------
------------------------------------3-------------------------------------
--PorcProvIntSuspensionCausacion    ---->   Porc_Prov_Inter     
	--SuspensionCausacion  2 ---->  Susp_Caus  (En el archivo 'ZonaGoldColombia' tiene quemado un cero)  
						--La salida de esta consulta siempre será cero, hay que tener
						--cuidado de que este valor no esté dividiendo en otra consulta.

'UPDATE [Staging].[Homologacion]
SET PorcProvIntSuspensionCausacion = IIF(SuspensionCausacion='SI',1,0)
WHERE CodigoPais = 147
GO
'


-----------------------------------3--------------------------------------------
--TotalProvGarantizadaCapital     ---->     Ttl_Prov_Part_Garan
	--CapitalGarantizado   1  ----->    Capital_No_Garan     ---> Todos sus valores son cero
	--PorcProviGarantizada 2  ----->    Prov_Part_Garan     ----> Todos sus valores son cero



'UPDATE [Staging].[Homologacion]
SET TotalProvGarantizadaCapital = (CapitalGarantizado*PorcProviGarantizada)
WHERE CodigoPais = 147 AND ClasCartera = 3
GO
'






---------------------------------------3-----------------------------------------
--TotalProvNoGarantizada	   ---->     Ttl_Prov_Part_No_Garan
	-- CapitalNoGarantizado   2 ----->  Capital_No_Garan    ----> Todos sus valores son cero
	-- PorcProvNoGarantizada  1 ----->  Prov_Part_No_Garan ----> Todos sus valores son cero


'UPDATE [Staging].[Homologacion]
SET TotalProvNoGarantizada = CapitalNoGarantizado*PorcProvNoGarantizada
WHERE CodigoPais = 148 AND ClasCartera = 3
GO
'







---------------------------------------4----------------------------------------	
--ProvisionCapitalTotal	  ---->    EIEP19

	--TotalProvGarantizadaCapital  3  ---->    Ttl_Prov_Part_Garan  --->   Todos sus valores son cero
	--TotalProvNoGarantizada   3  ----->     Ttl_Prov_Part_No_Garan   --->   Todos sus valores son cero

'UPDATE [Staging].[Homologacion]
SET ProvisionCapitalTotal = TotalProvGarantizadaCapital + TotalProvNoGarantizada
WHERE CodigoPais = 148 AND ClasCartera = 3
GO
'







-------------------------------------5------------------------------------------
--SubTotalProvSinProvAdicColombia	   ---->   SubProv

	--TotalProvisionIntereses	0----->     ProvI     ---> Está poblado con varios valores diferentes, incluye el cero 
	--ProvisionCapitalTotal	///  4-----> 	    EIEP19    ---> Todos sus valores son cero

'UPDATE [Staging].[Homologacion]
SET SubTotalProvSinProvAdicColombia = (TotalProvisionIntereses+ProvisionCapitalTotal)
WHERE CodigoPais = 147 AND ClasCartera = 3
GO
'






-------------------------------------------6------------------------------------
--AjusteProvisionAdicional    ---->   AjustProv

	-- CalDefEndeudamiento  0 ----> EIECAL 	(CalDefEndeudamiento en Colombia, según el archivo 'ZonaGoldColombia' solo
					                             ---tiene las calificaciones  ->  A , B , C.)
	-- SubTotalProvSinProvAdicColombia   5 ---->   SubProv
	-- ProvisionGeneralPorc1     1  ---->  Prov_1_Porc    ---> Tiene cero en sus valores
	-- ProvisionTotalPaisCOP	0 ---->    PROV_TTL_Col    ---> Está poblado con varios valores diferentes, incluye el cero 


'UPDATE
    Staging.Homologacion
SET
    AjusteProvisionAdicional = CASE
        WHEN CalDefEndeudamiento = 'A' THEN 0
        WHEN (SubTotalProvSinProvAdicColombia + ProvisionGeneralPorc1) > ProvisionTotalPaisCOP THEN 0
        ELSE (
            ProvisionTotalPaisCOP - SubTotalProvSinProvAdicColombia - ProvisionGeneralPorc1
        )
    END
WHERE CodigoPais = 147 AND ClasCartera = 3
'







